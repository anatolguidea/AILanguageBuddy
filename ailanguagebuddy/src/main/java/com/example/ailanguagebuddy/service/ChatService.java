package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.domain.AiTutorResult;
import com.example.ailanguagebuddy.domain.LearningContext;
import com.example.ailanguagebuddy.model.ChatMessage;
import com.example.ailanguagebuddy.repository.ChatMessageRepository;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Collections;
import java.util.UUID;
import java.time.LocalDateTime;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);
    private static final int PROMPT_HISTORY_LIMIT = 10;

    private final ChatModel chatModel;
    private final ChatMessageRepository repository;
    private final PromptBuilder promptBuilder;
    private final ObjectMapper objectMapper;

    public ChatService(ChatModel chatModel, ChatMessageRepository repository, PromptBuilder promptBuilder,
            ObjectMapper objectMapper) {
        this.chatModel = chatModel;
        this.repository = repository;
        this.promptBuilder = promptBuilder;
        this.objectMapper = objectMapper.copy()
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    /**
     * Sends the message to Groq and persists user/assistant messages for the given
     * user (except in VOICE_LIVE mode, where history is session-only and not persisted).
     * For VOICE_LIVE, pass the in-memory session history as voiceSessionHistory; when the
     * voice screen is closed, that history is discarded.
     */
    @Transactional
    public AiTutorResult askLanguageCoach(String userMessage, UUID userId, LearningContext context) {
        return askLanguageCoach(userMessage, userId, context, null);
    }

    @Transactional
    public AiTutorResult askLanguageCoach(String userMessage, UUID userId, LearningContext context, String voiceSessionHistory) {
        try {
            String mode = (context != null && context.mode() != null && !context.mode().isBlank())
                    ? context.mode()
                    : "general";
            // Voice live: use in-memory session history (when non-null). Same prompt as chat; no persistence for voice.
            boolean isVoiceCall = (voiceSessionHistory != null);
            String historyBlock = isVoiceCall
                    ? (voiceSessionHistory != null ? voiceSessionHistory : "")
                    : buildHistoryBlockForPrompt(userId, mode, PROMPT_HISTORY_LIMIT);
            var systemInstructions = new SystemMessage(
                    promptBuilder.buildSystemPrompt(context, historyBlock, userMessage));
            var userMsg = new UserMessage(userMessage);
            Prompt prompt = new Prompt(List.of(systemInstructions, userMsg));

            // Persist only for chat; voice uses session history and does not persist
            if (!isVoiceCall) {
                repository.saveAndFlush(new ChatMessage(userMessage, "user", userId, mode));
            }

            String rawResponse = chatModel.call(prompt)
                    .getResult()
                    .getOutput()
                    .getText();

            AiTutorResult result = parseTutorResult(rawResponse);

            // Voice call + non-English target: if the model replied in English, force-translate to target
            if (isVoiceCall && context != null) {
                String target = context.targetLanguage();
                if (target != null && !target.isBlank() && !"English".equalsIgnoreCase(target.trim())
                        && isLikelyEnglishReply(result.replyText())) {
                    String translated = translateReplyToTarget(result.replyText(), target);
                    if (translated != null && !translated.isBlank()) {
                        log.debug("Voice: translated reply from English to {}: {} -> {}", target, result.replyText(), translated);
                        result = new AiTutorResult(translated, result.correction(), result.tips());
                    }
                }
            }

            if (!isVoiceCall) {
                repository.saveAndFlush(new ChatMessage(
                        result.replyText(),
                        "assistant",
                        userId,
                        mode,
                        result.correction(),
                        result.tips()));
            }
            return result;
        } catch (Exception e) {
            throw new RuntimeException("AI request failed", e);
        }
    }

    private String buildHistoryBlockForPrompt(UUID userId, String mode, int limit) {
        if (userId == null) {
            return "";
        }
        String safeMode = mode == null || mode.isBlank() ? "general" : mode;
        List<ChatMessage> history = repository.findByUserIdAndModeOrderByCreatedAtDesc(
                userId,
                safeMode,
                PageRequest.of(0, limit));
        if (history.isEmpty()) {
            return "";
        }
        Collections.reverse(history);
        return history.stream()
                .map(msg -> "%s: %s".formatted(
                        msg.getRole() == null ? "unknown" : msg.getRole(),
                        msg.getContent() == null ? "" : msg.getContent().replace('\n', ' ').trim()))
                .collect(Collectors.joining("\n"));
    }

    public List<ChatMessage> loadHistory(UUID userId, int limit) {
        // Default to general if not specified (legacy support)
        return loadHistory(userId, "general", limit);
    }

    public List<ChatMessage> loadHistory(UUID userId, String mode, int limit) {
        var items = repository.findByUserIdAndModeOrderByCreatedAtDesc(userId, mode, PageRequest.of(0, limit));
        Collections.reverse(items);
        return items;
    }

    public List<ChatMessage> loadHistoryPage(UUID userId, String mode, int limit, LocalDateTime before) {
        int pageSize = limit + 1; // look ahead to know if there is a next page
        List<ChatMessage> items;
        if (before == null) {
            items = repository.findByUserIdAndModeOrderByCreatedAtDesc(userId, mode, PageRequest.of(0, pageSize));
        } else {
            items = repository.findByUserIdAndModeAndCreatedAtLessThanOrderByCreatedAtDesc(
                    userId,
                    mode,
                    before,
                    PageRequest.of(0, pageSize));
        }
        return items;
    }

    @Transactional
    public void deleteHistory(UUID userId, String mode) {
        repository.deleteByUserIdAndMode(userId, mode == null || mode.isBlank() ? "general" : mode);
    }

    private AiTutorResult parseTutorResult(String raw) {
        if (raw == null || raw.isBlank()) {
            return new AiTutorResult("No reply received from AI.", null, null, List.of(), List.of());
        }

        String trimmed = raw.trim();
        // Strip markdown code block if present
        if (trimmed.startsWith("```")) {
            int start = trimmed.indexOf('{');
            int end = trimmed.lastIndexOf('}');
            if (start >= 0 && end > start) trimmed = trimmed.substring(start, end + 1);
        }
        // Fix invalid JSON: LLM often outputs \' inside strings; JSON only allows \"
        String sanitized = trimmed.replace("\\'", "'");

        if (sanitized.startsWith("{")) {
            try {
                var node = objectMapper.readTree(sanitized);
                if (node.isObject()) {
                    String replyText = node.has("reply")
                            ? node.path("reply").asText("").trim()
                            : node.path("replyText").asText("").trim();
                    if (replyText.isEmpty()) replyText = raw;
                    String correction = node.has("correction") && !node.path("correction").isNull()
                            ? node.path("correction").asText("").trim()
                            : null;
                    String tips = node.has("tips") && !node.path("tips").isNull()
                            ? node.path("tips").asText("").trim()
                            : null;
                    if (correction != null && correction.isEmpty()) correction = null;
                    if (tips != null && tips.isEmpty()) tips = null;
                    return new AiTutorResult(replyText, correction, tips);
                }
            } catch (Exception ex) {
                log.warn("Failed to parse AI JSON, falling back to raw text: {}", ex.getMessage());
            }
        }

        return new AiTutorResult(raw, null, null, List.of(), List.of());
    }

    /** Heuristic: reply looks like English (common greetings/phrases). Used to trigger translation for voice. */
    private static boolean isLikelyEnglishReply(String text) {
        if (text == null || text.isBlank()) return false;
        String lower = text.trim().toLowerCase();
        if (lower.startsWith("hello") || lower.startsWith("hi ") || lower.startsWith("hi!")
                || lower.startsWith("how are you") || lower.startsWith("good morning")
                || lower.startsWith("good afternoon") || lower.startsWith("good evening")
                || lower.startsWith("nice to meet") || lower.startsWith("thanks ")
                || lower.startsWith("thank you") || lower.startsWith("good to talk")
                || lower.startsWith("how's your day") || lower.contains("how are you today")
                || lower.contains("it seems like") || lower.contains("could you tell me")
                || lower.contains("i think you might") || lower.contains("what's on your mind")) {
            return true;
        }
        return false;
    }

    /** Single LLM call: translate the reply to the target language. Used when voice model replied in English. */
    private String translateReplyToTarget(String replyText, String targetLanguageDisplayName) {
        if (replyText == null || replyText.isBlank() || targetLanguageDisplayName == null || targetLanguageDisplayName.isBlank()) {
            return replyText;
        }
        try {
            String systemPrompt = "You are a translator. Translate the following English text to " + targetLanguageDisplayName + ". "
                    + "Output ONLY the translation, nothing else. No quotes, no explanation. Keep the same tone (friendly, conversational).";
            Prompt prompt = new Prompt(List.of(
                    new SystemMessage(systemPrompt),
                    new UserMessage(replyText)));
            String out = chatModel.call(prompt).getResult().getOutput().getText();
            return out != null ? out.trim() : replyText;
        } catch (Exception e) {
            log.warn("Translation to {} failed, using original reply: {}", targetLanguageDisplayName, e.getMessage());
            return replyText;
        }
    }

    @Transactional
    public AiTutorResult getInitialMessage(UUID userId, LearningContext context) {
        try {
            String mode = (context != null && context.mode() != null && !context.mode().isBlank())
                    ? context.mode()
                    : "general";
            String historyBlock = buildHistoryBlockForPrompt(userId, mode, PROMPT_HISTORY_LIMIT);
            var systemInstructions = new SystemMessage(
                    promptBuilder.buildInitialGreetingPrompt(context, historyBlock));
            var userMsg = new UserMessage("(Start the conversation with a short greeting for this topic.)");
            Prompt prompt = new Prompt(List.of(systemInstructions, userMsg));

            String rawResponse = chatModel.call(prompt)
                    .getResult()
                    .getOutput()
                    .getText();

            AiTutorResult result = parseTutorResult(rawResponse);
            repository.saveAndFlush(new ChatMessage(
                    result.replyText(),
                    "assistant",
                    userId,
                    mode,
                    result.correction(),
                    result.tips()));
            return result;
        } catch (Exception e) {
            throw new RuntimeException("Initial message request failed", e);
        }
    }
}
