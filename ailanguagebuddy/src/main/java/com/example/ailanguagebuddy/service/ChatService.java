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
            return new AiTutorResult("No reply received from AI.", null, null, null, List.of(), List.of());
        }

        // Extract the first JSON object from the response.
        // Handles: plain JSON, markdown-wrapped (```json ... ```), and JSON embedded in prose.
        String jsonCandidate = extractJsonObject(raw);
        if (jsonCandidate != null) {
            // LLMs sometimes emit \' which is not valid JSON — normalize before parsing.
            String normalizedCandidate = jsonCandidate.replace("\\'", "'");
            try {
                var node = objectMapper.readTree(normalizedCandidate);
                if (node.isObject()) {
                    String replyText = nodeText(node, "reply", "replyText");
                    if (replyText.isEmpty()) replyText = raw.trim();
                    String translation = nullIfEmpty(nodeText(node, "translation"));
                    String correction  = nullIfEmpty(nodeText(node, "correction"));
                    String tips        = nullIfEmpty(nodeText(node, "tips"));
                    return new AiTutorResult(replyText, translation, correction, tips);
                }
            } catch (Exception ex) {
                log.warn("Failed to parse AI JSON candidate, falling back to raw text: {}", ex.getMessage());
            }
        }

        return new AiTutorResult(raw.trim(), null, null, null, List.of(), List.of());
    }

    /** Finds the first balanced JSON object in the raw string. Returns null if none found. */
    private static String extractJsonObject(String text) {
        int start = text.indexOf('{');
        if (start < 0) return null;
        int depth = 0;
        for (int i = start; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c == '{') depth++;
            else if (c == '}') {
                depth--;
                if (depth == 0) return text.substring(start, i + 1);
            }
        }
        return null;
    }

    private static String nodeText(com.fasterxml.jackson.databind.JsonNode node, String... keys) {
        for (String key : keys) {
            if (node.has(key) && !node.path(key).isNull()) {
                String v = node.path(key).asText("").trim();
                if (!v.isEmpty()) return v;
            }
        }
        return "";
    }

    private static String nullIfEmpty(String value) {
        return (value == null || value.isBlank()) ? null : value;
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

    public void prewarmVoiceModel(LearningContext context) {
        try {
            var effective = context != null ? context : LearningContext.defaultChat();
            var systemMessage = new SystemMessage(
                    promptBuilder.buildSystemPrompt(
                            new LearningContext(
                                    effective.targetLanguage(),
                                    effective.nativeLanguage(),
                                    "A1",
                                    "VOICE_LIVE",
                                    effective.instructionLocale()),
                            "",
                            "(model warmup)"));
            var userMessage = new UserMessage("Reply with a short JSON warmup response.");
            chatModel.call(new Prompt(List.of(systemMessage, userMessage)));
            log.debug("LLM prewarm completed for target language={}", effective.targetLanguage());
        } catch (Exception e) {
            log.warn("LLM prewarm failed: {}", e.getMessage());
        }
    }
}
