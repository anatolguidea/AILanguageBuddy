package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.config.TopicConfigService;
import com.example.ailanguagebuddy.domain.AiTutorResult;
import com.example.ailanguagebuddy.domain.LearningContext;
import com.example.ailanguagebuddy.model.ChatMessage;
import com.example.ailanguagebuddy.repository.ChatMessageRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ChatService")
class ChatServiceTest {

    @Mock
    private ChatModel chatModel;

    @Mock
    private ChatMessageRepository repository;

    @Mock
    private PromptBuilder promptBuilder;

    private ChatService chatService;

    // A real ObjectMapper — no need to mock it; tests exercise real JSON parsing.
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        chatService = new ChatService(chatModel, repository, promptBuilder, objectMapper);
    }

    // ---------------------------------------------------------------------------
    // Helper factory methods
    // ---------------------------------------------------------------------------

    private static LearningContext defaultCtx() {
        return new LearningContext("English", "Romanian", "B1", "general", "en");
    }

    private void stubLlmResponse(String text) {
        AssistantMessage assistantMessage = new AssistantMessage(text);
        Generation generation = new Generation(assistantMessage);
        ChatResponse chatResponse = new ChatResponse(List.of(generation));
        when(chatModel.call(any(Prompt.class))).thenReturn(chatResponse);
    }

    private void stubPromptBuilder() {
        when(promptBuilder.buildSystemPrompt(any(), any(), any())).thenReturn("system-prompt");
    }

    private void stubPromptBuilderInitial() {
        when(promptBuilder.buildInitialGreetingPrompt(any(), any())).thenReturn("greeting-prompt");
    }

    private ChatMessage makeChatMessage(String content, String role, UUID userId, String mode) {
        return new ChatMessage(content, role, userId, mode);
    }

    // ---------------------------------------------------------------------------
    // askLanguageCoach — normal chat mode (no persistence for voice)
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("askLanguageCoach (chat mode)")
    class AskLanguageCoachChatMode {

        @Test
        @DisplayName("happy path — valid JSON response is parsed and messages are persisted")
        void happyPath_validJson_parsedAndPersisted() {
            UUID userId = UUID.randomUUID();
            String jsonReply = "{\"reply\":\"Hello!\",\"translation\":\"Salut!\",\"correction\":\"\",\"tips\":\"\"}";
            stubPromptBuilder();
            stubLlmResponse(jsonReply);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hello", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("Hello!");
            assertThat(result.translation()).isEqualTo("Salut!");
            assertThat(result.correction()).isNull();  // empty string → null
            assertThat(result.tips()).isNull();         // empty string → null

            // Two saveAndFlush calls: one for user message, one for assistant message
            verify(repository, times(2)).saveAndFlush(any(ChatMessage.class));
        }

        @Test
        @DisplayName("persists user message with correct role and mode")
        void persistsUserMessageWithCorrectRoleAndMode() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Hi\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            chatService.askLanguageCoach("Hi there", userId, defaultCtx());

            ArgumentCaptor<ChatMessage> captor = ArgumentCaptor.forClass(ChatMessage.class);
            verify(repository, times(2)).saveAndFlush(captor.capture());

            ChatMessage userMsg = captor.getAllValues().get(0);
            assertThat(userMsg.getRole()).isEqualTo("user");
            assertThat(userMsg.getContent()).isEqualTo("Hi there");
            assertThat(userMsg.getMode()).isEqualTo("general");
            assertThat(userMsg.getUserId()).isEqualTo(userId);
        }

        @Test
        @DisplayName("null context falls back to mode=general")
        void nullContext_fallsBackToGeneralMode() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"OK\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Test", userId, null);

            assertThat(result.replyText()).isEqualTo("OK");
        }

        @Test
        @DisplayName("blank mode in context falls back to general")
        void blankMode_fallsBackToGeneral() {
            UUID userId = UUID.randomUUID();
            LearningContext ctx = new LearningContext("French", "English", "A2", "   ", "en");
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Bonjour\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, ctx);

            assertThat(result.replyText()).isEqualTo("Bonjour");
        }

        @Test
        @DisplayName("LLM throws RuntimeException — wraps in RuntimeException")
        void llmThrows_wrapsException() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));
            when(chatModel.call(any(Prompt.class))).thenThrow(new RuntimeException("LLM down"));

            assertThatThrownBy(() -> chatService.askLanguageCoach("Hello", userId, defaultCtx()))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("AI request failed");
        }

        @Test
        @DisplayName("prior history is loaded and included in prompt")
        void priorHistory_loadedForPrompt() {
            UUID userId = UUID.randomUUID();
            ChatMessage historicMsg = makeChatMessage("Previous message", "user", userId, "general");
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Sure\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(List.of(historicMsg));
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            chatService.askLanguageCoach("Next message", userId, defaultCtx());

            verify(promptBuilder).buildSystemPrompt(any(LearningContext.class), contains("Previous message"), eq("Next message"));
        }
    }

    // ---------------------------------------------------------------------------
    // askLanguageCoach — voice mode (voiceSessionHistory != null → no persistence)
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("askLanguageCoach (voice mode)")
    class AskLanguageCoachVoiceMode {

        @Test
        @DisplayName("voice mode — no messages persisted to repository")
        void voiceMode_noRepositoryPersistence() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Hello voice\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            chatService.askLanguageCoach("speak", userId, defaultCtx(), "user: Hello\nassistant: Hi");

            verify(repository, never()).saveAndFlush(any());
        }

        @Test
        @DisplayName("voice mode — uses provided session history instead of DB query")
        void voiceMode_usesSessionHistory() {
            UUID userId = UUID.randomUUID();
            String sessionHistory = "user: Bonjour\nassistant: Bonjour!";
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Tres bien\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            chatService.askLanguageCoach("Comment ca va", userId, defaultCtx(), sessionHistory);

            // DB history should not be queried when voice session history is provided
            verify(repository, never()).findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any());
            verify(promptBuilder).buildSystemPrompt(any(), eq(sessionHistory), eq("Comment ca va"));
        }

        @Test
        @DisplayName("voice mode — empty session history string is used as-is")
        void voiceMode_emptySessionHistory_noDbQuery() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"Hi\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx(), "");

            assertThat(result.replyText()).isEqualTo("Hi");
            verify(repository, never()).saveAndFlush(any());
        }

        @Test
        @DisplayName("voice mode — result is returned from LLM response")
        void voiceMode_returnsLlmResult() {
            UUID userId = UUID.randomUUID();
            String json = "{\"reply\":\"Voice reply here\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}";
            stubPromptBuilder();
            stubLlmResponse(json);

            AiTutorResult result = chatService.askLanguageCoach("Anything", userId, defaultCtx(), "prior: hi");

            assertThat(result.replyText()).isEqualTo("Voice reply here");
        }
    }

    // ---------------------------------------------------------------------------
    // parseTutorResult — tested via public entry points
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("parseTutorResult (via askLanguageCoach)")
    class ParseTutorResult {

        @Test
        @DisplayName("valid JSON with all fields populated — correctly mapped")
        void validJson_allFieldsPopulated() {
            UUID userId = UUID.randomUUID();
            String json = "{\"reply\":\"Great job!\",\"translation\":\"Bravo!\",\"correction\":\"Fixed\",\"tips\":\"Use past tense\"}";
            stubPromptBuilder();
            stubLlmResponse(json);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Good", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("Great job!");
            assertThat(result.translation()).isEqualTo("Bravo!");
            assertThat(result.correction()).isEqualTo("Fixed");
            assertThat(result.tips()).isEqualTo("Use past tense");
        }

        @Test
        @DisplayName("markdown-wrapped JSON (```json\\n{...}\\n```) is stripped and parsed")
        void markdownWrappedJson_isStrippedAndParsed() {
            UUID userId = UUID.randomUUID();
            String markdown = "```json\n{\"reply\":\"Parsed!\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}\n```";
            stubPromptBuilder();
            stubLlmResponse(markdown);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("Parsed!");
        }

        @Test
        @DisplayName("plain text (no '{') falls back to raw text as replyText")
        void plainText_fallsBackToRaw() {
            UUID userId = UUID.randomUUID();
            String plainText = "Hello, how are you today?";
            stubPromptBuilder();
            stubLlmResponse(plainText);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo(plainText);
            assertThat(result.translation()).isNull();
            assertThat(result.correction()).isNull();
            assertThat(result.tips()).isNull();
        }

        @Test
        @DisplayName("LLM returns null text — returns 'No reply received from AI.' fallback")
        void nullLlmText_returnsDefaultFallback() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse(null);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("No reply received from AI.");
        }

        @Test
        @DisplayName("LLM returns blank text — returns 'No reply received from AI.' fallback")
        void blankLlmText_returnsDefaultFallback() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilder();
            stubLlmResponse("   ");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("No reply received from AI.");
        }

        @Test
        @DisplayName("JSON with escaped apostrophes (\\\\') is sanitized and parsed")
        void escapedApostrophes_sanitizedBeforeParsing() {
            UUID userId = UUID.randomUUID();
            // LLM sometimes emits \' inside JSON strings — invalid per RFC; service should fix it
            String jsonWithEscapedApostrophes = "{\"reply\":\"It\\'s fine!\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}";
            stubPromptBuilder();
            stubLlmResponse(jsonWithEscapedApostrophes);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("It's fine!");
        }

        @Test
        @DisplayName("JSON with 'replyText' field (alternative key) is parsed correctly")
        void jsonWithReplyTextField_parsedCorrectly() {
            UUID userId = UUID.randomUUID();
            String json = "{\"replyText\":\"Alternative key\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}";
            stubPromptBuilder();
            stubLlmResponse(json);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("Alternative key");
        }

        @Test
        @DisplayName("JSON with null correction and tips fields returns null (not empty string)")
        void jsonWithNullFields_returnsNull() {
            UUID userId = UUID.randomUUID();
            String json = "{\"reply\":\"Hello\",\"translation\":null,\"correction\":null,\"tips\":null}";
            stubPromptBuilder();
            stubLlmResponse(json);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            assertThat(result.correction()).isNull();
            assertThat(result.tips()).isNull();
            assertThat(result.translation()).isNull();
        }

        @Test
        @DisplayName("invalid JSON (malformed) falls back to raw text")
        void invalidJson_fallsBackToRaw() {
            UUID userId = UUID.randomUUID();
            String malformed = "{reply: 'not valid json at all'";
            stubPromptBuilder();
            stubLlmResponse(malformed);
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.askLanguageCoach("Hi", userId, defaultCtx());

            // Falls back to raw text since JSON parse will fail
            assertThat(result.replyText()).isNotNull();
        }
    }

    // ---------------------------------------------------------------------------
    // loadHistory
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("loadHistory")
    class LoadHistory {

        @Test
        @DisplayName("delegates to repository with correct userId, mode and limit")
        void delegatesToRepository() {
            UUID userId = UUID.randomUUID();
            ChatMessage msg1 = makeChatMessage("msg1", "user", userId, "general");
            ChatMessage msg2 = makeChatMessage("msg2", "assistant", userId, "general");
            // Repository returns desc; service reverses to asc.
            // Must be a mutable list because ChatService calls Collections.reverse() on it.
            List<ChatMessage> mutableList = new ArrayList<>(List.of(msg2, msg1));
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(mutableList);

            List<ChatMessage> result = chatService.loadHistory(userId, "general", 10);

            assertThat(result).hasSize(2);
            // After Collections.reverse, msg1 (index 1 originally) comes first
            assertThat(result.get(0).getContent()).isEqualTo("msg1");
            assertThat(result.get(1).getContent()).isEqualTo("msg2");
        }

        @Test
        @DisplayName("no-arg mode overload defaults to 'general'")
        void noArgModeOverload_defaultsToGeneral() {
            UUID userId = UUID.randomUUID();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());

            List<ChatMessage> result = chatService.loadHistory(userId, 5);

            verify(repository).findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any());
            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("empty repository result returns empty list")
        void emptyRepository_returnsEmptyList() {
            UUID userId = UUID.randomUUID();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());

            List<ChatMessage> result = chatService.loadHistory(userId, "general", 10);

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("passes correct PageRequest size to repository")
        void passesCorrectPageRequestSize() {
            UUID userId = UUID.randomUUID();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());

            chatService.loadHistory(userId, "general", 20);

            ArgumentCaptor<org.springframework.data.domain.Pageable> pageableCaptor =
                    ArgumentCaptor.forClass(org.springframework.data.domain.Pageable.class);
            verify(repository).findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), pageableCaptor.capture());
            assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(20);
        }
    }

    // ---------------------------------------------------------------------------
    // loadHistoryPage — cursor pagination
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("loadHistoryPage")
    class LoadHistoryPage {

        @Test
        @DisplayName("null 'before' cursor uses findByUserIdAndMode without date filter")
        void nullBefore_usesNonCursorQuery() {
            UUID userId = UUID.randomUUID();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any()))
                    .thenReturn(Collections.emptyList());

            List<ChatMessage> result = chatService.loadHistoryPage(userId, "general", 10, null);

            assertThat(result).isEmpty();
            verify(repository).findByUserIdAndModeOrderByCreatedAtDesc(eq(userId), eq("general"), any());
            verify(repository, never()).findByUserIdAndModeAndCreatedAtLessThanOrderByCreatedAtDesc(
                    any(), any(), any(), any());
        }

        @Test
        @DisplayName("non-null 'before' cursor uses date-filtered query")
        void nonNullBefore_usesCursorQuery() {
            UUID userId = UUID.randomUUID();
            LocalDateTime cursor = LocalDateTime.now().minusHours(1);
            when(repository.findByUserIdAndModeAndCreatedAtLessThanOrderByCreatedAtDesc(
                    eq(userId), eq("general"), eq(cursor), any()))
                    .thenReturn(Collections.emptyList());

            List<ChatMessage> result = chatService.loadHistoryPage(userId, "general", 10, cursor);

            assertThat(result).isEmpty();
            verify(repository).findByUserIdAndModeAndCreatedAtLessThanOrderByCreatedAtDesc(
                    eq(userId), eq("general"), eq(cursor), any());
            verify(repository, never()).findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any());
        }

        @Test
        @DisplayName("look-ahead page size is limit + 1")
        void lookAheadPageSize_isLimitPlusOne() {
            UUID userId = UUID.randomUUID();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());

            chatService.loadHistoryPage(userId, "general", 15, null);

            ArgumentCaptor<org.springframework.data.domain.Pageable> pageableCaptor =
                    ArgumentCaptor.forClass(org.springframework.data.domain.Pageable.class);
            verify(repository).findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), pageableCaptor.capture());
            assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(16); // 15 + 1 look-ahead
        }

        @Test
        @DisplayName("returns raw repository result (no reversal)")
        void returnsRawResult() {
            UUID userId = UUID.randomUUID();
            ChatMessage msg = makeChatMessage("content", "user", userId, "general");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(List.of(msg));

            List<ChatMessage> result = chatService.loadHistoryPage(userId, "general", 10, null);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getContent()).isEqualTo("content");
        }
    }

    // ---------------------------------------------------------------------------
    // deleteHistory
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("deleteHistory")
    class DeleteHistory {

        @Test
        @DisplayName("delegates to repository.deleteByUserIdAndMode with correct arguments")
        void delegatesToRepository() {
            UUID userId = UUID.randomUUID();

            chatService.deleteHistory(userId, "travel");

            verify(repository).deleteByUserIdAndMode(userId, "travel");
        }

        @Test
        @DisplayName("null mode normalised to 'general'")
        void nullMode_normalisedToGeneral() {
            UUID userId = UUID.randomUUID();

            chatService.deleteHistory(userId, null);

            verify(repository).deleteByUserIdAndMode(userId, "general");
        }

        @Test
        @DisplayName("blank mode normalised to 'general'")
        void blankMode_normalisedToGeneral() {
            UUID userId = UUID.randomUUID();

            chatService.deleteHistory(userId, "   ");

            verify(repository).deleteByUserIdAndMode(userId, "general");
        }

        @Test
        @DisplayName("empty string mode normalised to 'general'")
        void emptyMode_normalisedToGeneral() {
            UUID userId = UUID.randomUUID();

            chatService.deleteHistory(userId, "");

            verify(repository).deleteByUserIdAndMode(userId, "general");
        }
    }

    // ---------------------------------------------------------------------------
    // getInitialMessage
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("getInitialMessage")
    class GetInitialMessage {

        @Test
        @DisplayName("happy path — assistant greeting is persisted")
        void happyPath_assistantGreetingPersisted() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilderInitial();
            stubLlmResponse("{\"reply\":\"Welcome!\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.getInitialMessage(userId, defaultCtx());

            assertThat(result.replyText()).isEqualTo("Welcome!");
            ArgumentCaptor<ChatMessage> captor = ArgumentCaptor.forClass(ChatMessage.class);
            verify(repository).saveAndFlush(captor.capture());
            assertThat(captor.getValue().getRole()).isEqualTo("assistant");
            assertThat(captor.getValue().getContent()).isEqualTo("Welcome!");
        }

        @Test
        @DisplayName("null context — uses default chat context")
        void nullContext_usesDefault() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilderInitial();
            stubLlmResponse("{\"reply\":\"Hi!\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            AiTutorResult result = chatService.getInitialMessage(userId, null);

            assertThat(result.replyText()).isEqualTo("Hi!");
        }

        @Test
        @DisplayName("LLM throws — wraps in RuntimeException with meaningful message")
        void llmThrows_wrapsException() {
            UUID userId = UUID.randomUUID();
            stubPromptBuilderInitial();
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(chatModel.call(any(Prompt.class))).thenThrow(new RuntimeException("timeout"));

            assertThatThrownBy(() -> chatService.getInitialMessage(userId, defaultCtx()))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Initial message request failed");
        }

        @Test
        @DisplayName("mode from context is used for persisting assistant message")
        void modeFromContext_usedForPersistence() {
            UUID userId = UUID.randomUUID();
            LearningContext ctx = new LearningContext("Spanish", "English", "A1", "travel", "en");
            stubPromptBuilderInitial();
            stubLlmResponse("{\"reply\":\"Hola!\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");
            when(repository.findByUserIdAndModeOrderByCreatedAtDesc(any(), any(), any()))
                    .thenReturn(Collections.emptyList());
            when(repository.saveAndFlush(any())).thenAnswer(inv -> inv.getArgument(0));

            chatService.getInitialMessage(userId, ctx);

            ArgumentCaptor<ChatMessage> captor = ArgumentCaptor.forClass(ChatMessage.class);
            verify(repository).saveAndFlush(captor.capture());
            assertThat(captor.getValue().getMode()).isEqualTo("travel");
        }
    }

    // ---------------------------------------------------------------------------
    // prewarmVoiceModel
    // ---------------------------------------------------------------------------

    @Nested
    @DisplayName("prewarmVoiceModel")
    class PrewarmVoiceModel {

        @Test
        @DisplayName("happy path — does not throw even when LLM succeeds")
        void happyPath_doesNotThrow() {
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"warm\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            // Should not throw
            chatService.prewarmVoiceModel(defaultCtx());

            verify(chatModel).call(any(Prompt.class));
        }

        @Test
        @DisplayName("LLM throws — swallowed silently, no exception propagated")
        void llmThrows_noExceptionPropagated() {
            stubPromptBuilder();
            when(chatModel.call(any(Prompt.class))).thenThrow(new RuntimeException("network error"));

            // prewarmVoiceModel catches all exceptions — must not rethrow
            chatService.prewarmVoiceModel(defaultCtx());
        }

        @Test
        @DisplayName("null context — uses defaultChat() without throwing")
        void nullContext_usesDefault() {
            stubPromptBuilder();
            stubLlmResponse("{\"reply\":\"warm\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            chatService.prewarmVoiceModel(null);

            verify(chatModel).call(any(Prompt.class));
        }

        @Test
        @DisplayName("always uses VOICE_LIVE mode for the warmup prompt")
        void alwaysUsesVoiceLiveMode() {
            when(promptBuilder.buildSystemPrompt(any(LearningContext.class), any(), any()))
                    .thenReturn("warmup-prompt");
            stubLlmResponse("{\"reply\":\"warm\",\"translation\":\"\",\"correction\":\"\",\"tips\":\"\"}");

            chatService.prewarmVoiceModel(defaultCtx());

            ArgumentCaptor<LearningContext> ctxCaptor = ArgumentCaptor.forClass(LearningContext.class);
            verify(promptBuilder).buildSystemPrompt(ctxCaptor.capture(), any(), any());
            assertThat(ctxCaptor.getValue().mode()).isEqualTo("VOICE_LIVE");
        }
    }
}
