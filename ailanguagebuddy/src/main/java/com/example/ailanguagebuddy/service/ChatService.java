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
     * user.
     * Returns a structured result that includes corrections and vocabulary when
     * available.
     */
    @Transactional
    public AiTutorResult askLanguageCoach(String userMessage, UUID userId, LearningContext context) {
        try {
            String mode = (context != null && context.mode() != null && !context.mode().isBlank())
                    ? context.mode()
                    : "general";
            String historyBlock = buildHistoryBlockForPrompt(userId, mode, PROMPT_HISTORY_LIMIT);
            var systemInstructions = new SystemMessage(
                    promptBuilder.buildSystemPrompt(context, historyBlock, userMessage));
            var userMsg = new UserMessage(userMessage);
            Prompt prompt = new Prompt(List.of(systemInstructions, userMsg));

            // Save user message with mode and flush immediately.
            repository.saveAndFlush(new ChatMessage(userMessage, "user", userId, mode));

            String rawResponse = chatModel.call(prompt)
                    .getResult()
                    .getOutput()
                    .getText();

            AiTutorResult result = parseTutorResult(rawResponse);

            // Persist what the user actually sees in the chat bubble, flush immediately.
            repository.saveAndFlush(new ChatMessage(result.replyText(), "assistant", userId, mode));
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

    private AiTutorResult parseTutorResult(String raw) {
        if (raw == null || raw.isBlank()) {
            return new AiTutorResult("No reply received from AI.", List.of(), List.of());
        }

        String trimmed = raw.trim();
        // Only attempt to parse as JSON if it looks like a JSON object
        if (trimmed.startsWith("{")) {
            try {
                var node = objectMapper.readTree(raw);
                if (node.isObject()) {
                    var replyText = node.path("replyText").asText(raw);

                    var correctionsNode = node.path("corrections");
                    List<com.example.ailanguagebuddy.domain.Correction> corrections = correctionsNode.isArray()
                            ? objectMapper.readerForListOf(com.example.ailanguagebuddy.domain.Correction.class)
                                    .readValue(correctionsNode)
                            : List.of();

                    var vocabNode = node.path("vocabulary");
                    List<com.example.ailanguagebuddy.domain.VocabularyItem> vocabulary = vocabNode.isArray()
                            ? objectMapper.readerForListOf(com.example.ailanguagebuddy.domain.VocabularyItem.class)
                                    .readValue(vocabNode)
                            : List.of();

                    return new AiTutorResult(replyText, corrections, vocabulary);
                }
            } catch (Exception ex) {
                log.warn("Failed to parse AI JSON, falling back to raw text: {}", ex.getMessage());
            }
        }

        // Fallback: treat the whole response as plain text.
        return new AiTutorResult(raw, List.of(), List.of());
    }
}
