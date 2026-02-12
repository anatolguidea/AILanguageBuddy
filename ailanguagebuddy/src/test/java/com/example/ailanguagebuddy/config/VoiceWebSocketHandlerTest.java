package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.service.voice.ProcessVoiceTurnUseCase;
import com.example.ailanguagebuddy.service.voice.GeneratePartialTranscriptUseCase;
import com.example.ailanguagebuddy.service.voice.TextToSpeechPort;
import com.example.ailanguagebuddy.service.voice.VoiceTurnException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketMessage;
import org.springframework.web.socket.WebSocketSession;

import java.net.URI;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class VoiceWebSocketHandlerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private ProcessVoiceTurnUseCase useCase;
    private GeneratePartialTranscriptUseCase partialUseCase;
    private TextToSpeechPort ttsPort;
    private JwtDecoder jwtDecoder;
    private VoiceWebSocketHandler handler;
    private UUID userId;

    @BeforeEach
    void setUp() {
        useCase = mock(ProcessVoiceTurnUseCase.class);
        when(useCase.isStreamingAvailable()).thenReturn(false);
        partialUseCase = mock(GeneratePartialTranscriptUseCase.class);
        ttsPort = mock(TextToSpeechPort.class);
        jwtDecoder = mock(JwtDecoder.class);
        handler = new VoiceWebSocketHandler(useCase, partialUseCase, ttsPort, jwtDecoder, objectMapper);
        userId = UUID.randomUUID();
    }

    @Test
    void sendsConnectedEventAfterAuthenticatedHandshake() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s1", userId);

        handler.afterConnectionEstablished(fixture.session);

        JsonNode connected = firstTextEvent(fixture.sentMessages);
        assertEquals(1, connected.path("v").asInt());
        assertEquals("connected", connected.path("event").asText());
        List<JsonNode> events = textEvents(fixture.sentMessages);
        JsonNode jitterConfig = findEvent(events, "jitter_config");
        assertEquals(2, jitterConfig.path("data").path("prebufferChunks").asInt());
        assertEquals(12288, jitterConfig.path("data").path("prebufferBytes").asInt());
        assertTrue(fixture.attributes.containsKey("userId"));
        assertEquals(userId, fixture.attributes.get("userId"));
    }

    @Test
    void emitsProcessingTranscriptAssistantAndAudioOnSuccessfulTurn() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s2", userId);
        when(useCase.executeTextOnly(any(byte[].class), eq(userId)))
                .thenReturn(new ProcessVoiceTurnUseCase.TurnTextResult("hello", "hi there"));
        when(ttsPort.synthesize("hi there")).thenReturn(new byte[] { 9, 8, 7 });

        handler.afterConnectionEstablished(fixture.session);
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(new byte[] { 1, 2, 3 }));
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"end_turn\"}"));
        awaitEvent(fixture.sentMessages, "audio_end", 2000);

        List<JsonNode> textEvents = textEvents(fixture.sentMessages);
        assertEquals("connected", textEvents.get(0).path("event").asText());
        assertEquals(1, textEvents.get(0).path("v").asInt());
        JsonNode processing = findEvent(textEvents, "processing");
        JsonNode transcript = findEvent(textEvents, "transcript");
        JsonNode assistant = findEvent(textEvents, "assistant_text");
        assertEquals(1, processing.path("v").asInt());
        assertEquals("hello", transcript.path("message").asText());
        assertEquals(1, assistant.path("v").asInt());
        assertTrue(textEvents.stream().anyMatch(e -> "audio_end".equals(e.path("event").asText())));

        BinaryMessage binary = firstBinaryEvent(fixture.sentMessages);
        byte[] audio = new byte[binary.getPayload().remaining()];
        binary.getPayload().asReadOnlyBuffer().get(audio);
        assertArrayEquals(new byte[] { 9, 8, 7 }, audio);
    }

    @Test
    void emitsStructuredErrorEventWhenUseCaseFails() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s3", userId);
        when(useCase.executeTextOnly(any(byte[].class), eq(userId)))
                .thenThrow(new VoiceTurnException("empty_transcript", "No speech detected"));

        handler.afterConnectionEstablished(fixture.session);
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(new byte[] { 3, 4, 5 }));
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"end_turn\"}"));
        awaitEvent(fixture.sentMessages, "error", 2000);

        List<JsonNode> textEvents = textEvents(fixture.sentMessages);
        JsonNode error = textEvents.get(textEvents.size() - 1);
        assertEquals(1, error.path("v").asInt());
        assertEquals("error", error.path("event").asText());
        assertEquals("empty_transcript", error.path("code").asText());
        assertEquals("No speech detected", error.path("message").asText());
    }

    @Test
    void emitsPartialTranscriptEventsForLongTranscript() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s8", userId);
        when(useCase.executeTextOnly(any(byte[].class), eq(userId)))
                .thenReturn(new ProcessVoiceTurnUseCase.TurnTextResult(
                        "this is a long transcript",
                        "reply"));
        when(ttsPort.synthesize("reply")).thenReturn(new byte[] { 1, 2, 3 });

        handler.afterConnectionEstablished(fixture.session);
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"start_turn\"}"));
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(new byte[] { 1, 2, 3 }));
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"end_turn\"}"));
        awaitEvent(fixture.sentMessages, "audio_end", 2000);

        List<JsonNode> events = textEvents(fixture.sentMessages);
        long partialCount = events.stream()
                .filter(e -> "partial_transcript".equals(e.path("event").asText()))
                .count();
        assertTrue(partialCount > 0);
    }

    @Test
    void closesConnectionWhenTokenIsInvalid() throws Exception {
        WebSocketSession session = mock(WebSocketSession.class);
        Map<String, Object> attributes = new ConcurrentHashMap<>();
        List<WebSocketMessage<?>> sentMessages = new ArrayList<>();
        when(session.getId()).thenReturn("s4");
        when(session.getUri()).thenReturn(URI.create("ws://localhost/ws/voice?token=bad"));
        when(session.getAttributes()).thenReturn(attributes);
        when(session.isOpen()).thenReturn(true);
        doAnswer(invocation -> {
            sentMessages.add(invocation.getArgument(0));
            return null;
        }).when(session).sendMessage(any(WebSocketMessage.class));
        when(jwtDecoder.decode("bad")).thenThrow(new RuntimeException("Invalid token"));

        handler.afterConnectionEstablished(session);

        JsonNode error = firstTextEvent(sentMessages);
        assertEquals(1, error.path("v").asInt());
        assertEquals("error", error.path("event").asText());
        verify(session).close(any(CloseStatus.class));
    }

    @Test
    void startTurnControlEventResetsBufferedAudio() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s5", userId);
        when(useCase.executeTextOnly(any(byte[].class), eq(userId)))
                .thenReturn(new ProcessVoiceTurnUseCase.TurnTextResult("ok", "ok"));
        when(ttsPort.synthesize("ok")).thenReturn(new byte[] { 1 });

        handler.afterConnectionEstablished(fixture.session);
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(new byte[] { 1, 2 }));
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"start_turn\"}"));
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(new byte[] { 9, 9, 9 }));
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"end_turn\"}"));
        awaitEvent(fixture.sentMessages, "audio_end", 2000);

        verify(useCase).executeTextOnly(argThat(bytes -> Arrays.equals(bytes, new byte[] { 9, 9, 9 })), eq(userId));
    }

    @Test
    void emitsErrorWhenAudioTurnExceedsConfiguredLimit() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s6", userId);
        byte[] tooLarge = new byte[2_000_001];

        handler.afterConnectionEstablished(fixture.session);
        handler.handleBinaryMessage(fixture.session, new BinaryMessage(tooLarge));

        List<JsonNode> textEvents = textEvents(fixture.sentMessages);
        JsonNode error = textEvents.get(textEvents.size() - 1);
        assertEquals(1, error.path("v").asInt());
        assertEquals("error", error.path("event").asText());
        assertEquals("audio_too_large", error.path("code").asText());
    }

    @Test
    void emitsInvalidStateWhenEndTurnArrivesWithoutListeningState() throws Exception {
        SessionFixture fixture = createAuthenticatedSession("s7", userId);

        handler.afterConnectionEstablished(fixture.session);
        handler.handleTextMessage(fixture.session, new TextMessage("{\"event\":\"end_turn\"}"));

        List<JsonNode> textEvents = textEvents(fixture.sentMessages);
        JsonNode error = textEvents.get(textEvents.size() - 1);
        assertEquals(1, error.path("v").asInt());
        assertEquals("error", error.path("event").asText());
        assertEquals("invalid_state", error.path("code").asText());
    }

    private SessionFixture createAuthenticatedSession(String sessionId, UUID userId) throws Exception {
        WebSocketSession session = mock(WebSocketSession.class);
        Map<String, Object> attributes = new ConcurrentHashMap<>();
        List<WebSocketMessage<?>> sentMessages = new ArrayList<>();
        when(session.getId()).thenReturn(sessionId);
        when(session.getUri()).thenReturn(URI.create("ws://localhost/ws/voice?token=good"));
        when(session.getAttributes()).thenReturn(attributes);
        when(session.isOpen()).thenReturn(true);
        doAnswer(invocation -> {
            sentMessages.add(invocation.getArgument(0));
            return null;
        }).when(session).sendMessage(any(WebSocketMessage.class));

        Jwt jwt = Jwt.withTokenValue("good")
                .header("alg", "HS256")
                .subject(userId.toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(jwtDecoder.decode("good")).thenReturn(jwt);

        return new SessionFixture(session, attributes, sentMessages);
    }

    private JsonNode firstTextEvent(List<WebSocketMessage<?>> messages) throws Exception {
        for (WebSocketMessage<?> message : messages) {
            if (message instanceof TextMessage textMessage) {
                return objectMapper.readTree(textMessage.getPayload());
            }
        }
        throw new IllegalStateException("No text event found");
    }

    private BinaryMessage firstBinaryEvent(List<WebSocketMessage<?>> messages) {
        for (WebSocketMessage<?> message : messages) {
            if (message instanceof BinaryMessage binaryMessage) {
                return binaryMessage;
            }
        }
        throw new IllegalStateException("No binary event found");
    }

    private List<JsonNode> textEvents(List<WebSocketMessage<?>> messages) throws Exception {
        List<JsonNode> events = new ArrayList<>();
        for (WebSocketMessage<?> message : messages) {
            if (message instanceof TextMessage textMessage) {
                events.add(objectMapper.readTree(textMessage.getPayload()));
            }
        }
        return events;
    }

    private JsonNode findEvent(List<JsonNode> events, String eventType) {
        return events.stream()
                .filter(event -> eventType.equals(event.path("event").asText()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Expected event not found: " + eventType));
    }

    /**
     * Poll the sent messages list until a text event with the given type appears,
     * or until the timeout expires. This handles the async processBufferedAudio
     * dispatch.
     */
    private void awaitEvent(List<WebSocketMessage<?>> sentMessages, String eventType, long timeoutMs)
            throws Exception {
        long deadline = System.currentTimeMillis() + timeoutMs;
        while (System.currentTimeMillis() < deadline) {
            for (WebSocketMessage<?> msg : List.copyOf(sentMessages)) {
                if (msg instanceof TextMessage txt) {
                    JsonNode node = objectMapper.readTree(txt.getPayload());
                    if (eventType.equals(node.path("event").asText())) {
                        return;
                    }
                }
            }
            Thread.sleep(25);
        }
        throw new IllegalStateException("Timed out waiting for event: " + eventType);
    }

    private record SessionFixture(WebSocketSession session, Map<String, Object> attributes,
            List<WebSocketMessage<?>> sentMessages) {
    }
}
