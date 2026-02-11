package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.service.voice.ProcessVoiceTurnUseCase;
import com.example.ailanguagebuddy.service.voice.GeneratePartialTranscriptUseCase;
import com.example.ailanguagebuddy.service.voice.PartialSpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.SpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.TextToSpeechPort;
import com.example.ailanguagebuddy.service.voice.TutorModelPort;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.autoconfigure.exclude=org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration,org.springframework.boot.hibernate.autoconfigure.HibernateJpaAutoConfiguration,org.springframework.boot.security.autoconfigure.SecurityAutoConfiguration,org.springframework.boot.security.autoconfigure.web.servlet.ServletWebSecurityAutoConfiguration,org.springframework.boot.security.autoconfigure.web.servlet.SecurityFilterAutoConfiguration,org.springframework.boot.security.oauth2.server.resource.autoconfigure.servlet.OAuth2ResourceServerAutoConfiguration,org.springframework.boot.security.autoconfigure.actuate.web.servlet.ManagementWebSecurityAutoConfiguration",
                "spring.ai.model.chat=none",
                "spring.ai.model.audio.speech=none",
                "spring.ai.model.audio.transcription=none",
                "spring.ai.model.embedding=none",
                "spring.ai.model.image=none",
                "spring.ai.model.moderation=none"
        },
        classes = VoiceWebSocketIntegrationTest.TestApplication.class)
class VoiceWebSocketIntegrationTest {

    private static final UUID TEST_USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @SpringBootConfiguration
    @EnableAutoConfiguration
    @Import({ WebSocketConfig.class, VoiceWebSocketHandler.class })
    static class TestApplication {
        @Bean
        ObjectMapper objectMapper() {
            return new ObjectMapper();
        }

        @Bean
        VoiceTestState voiceTestState() {
            return new VoiceTestState();
        }

        @Bean
        JwtDecoder jwtDecoder() {
            return token -> {
                if ("bad-token".equals(token)) {
                    throw new IllegalArgumentException("Invalid token");
                }
                return Jwt.withTokenValue(token)
                    .header("alg", "HS256")
                    .subject(TEST_USER_ID.toString())
                    .issuedAt(Instant.now())
                    .expiresAt(Instant.now().plusSeconds(3600))
                    .build();
            };
        }

        @Bean
        SpeechToTextPort speechToTextPort(VoiceTestState state) {
            return audioBytes -> {
                state.lastAudio.set(audioBytes);
                return state.transcript.get();
            };
        }

        @Bean
        PartialSpeechToTextPort partialSpeechToTextPort(VoiceTestState state) {
            return audioBytes -> state.transcript.get();
        }

        @Bean
        TutorModelPort tutorModelPort(VoiceTestState state) {
            return (userText, userId) -> state.replyText.get();
        }

        @Bean
        TextToSpeechPort textToSpeechPort(VoiceTestState state) {
            return text -> state.replyAudio.get();
        }

        @Bean
        ProcessVoiceTurnUseCase processVoiceTurnUseCase(SpeechToTextPort stt, TutorModelPort tutor,
                TextToSpeechPort tts) {
            return new ProcessVoiceTurnUseCase(stt, tutor, tts);
        }

        @Bean
        GeneratePartialTranscriptUseCase generatePartialTranscriptUseCase(PartialSpeechToTextPort partialStt) {
            return new GeneratePartialTranscriptUseCase(partialStt);
        }
    }

    @LocalServerPort
    int port;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    VoiceTestState voiceTestState;

    @BeforeEach
    void resetState() {
        voiceTestState.transcript.set("hello");
        voiceTestState.replyText.set("Hi from AI");
        voiceTestState.replyAudio.set(new byte[] { 5, 6, 7 });
        voiceTestState.lastAudio.set(null);
    }

    @Test
    void websocketEmitsStructuredEventsAndBinaryAudio() throws Exception {
        TestListener listener = new TestListener();
        WebSocket webSocket = connect(listener);

        JsonNode connected = listener.awaitText(objectMapper);
        assertEquals(1, connected.path("v").asInt());
        assertEquals("connected", connected.path("event").asText());
        assertEquals("Voice socket ready", connected.path("message").asText());
        JsonNode jitterConfig = listener.awaitEvent(objectMapper, "jitter_config", 2);
        assertEquals(2, jitterConfig.path("data").path("prebufferChunks").asInt());

        webSocket.sendBinary(ByteBuffer.wrap(new byte[] { 1, 2, 3 }), true).join();
        webSocket.sendText("{\"v\":1,\"event\":\"end_turn\"}", true).join();

        JsonNode processing = listener.awaitEvent(objectMapper, "processing", 3);
        assertEquals(1, processing.path("v").asInt());
        assertEquals("processing", processing.path("event").asText());
        assertTrue(processing.has("message"));

        JsonNode transcript = listener.awaitEvent(objectMapper, "transcript", 4);
        assertEquals(1, transcript.path("v").asInt());
        assertEquals("transcript", transcript.path("event").asText());
        assertEquals("hello", transcript.path("message").asText());

        JsonNode assistant = listener.awaitEvent(objectMapper, "assistant_text", 4);
        assertEquals(1, assistant.path("v").asInt());
        assertEquals("assistant_text", assistant.path("event").asText());
        assertEquals("Hi from AI", assistant.path("message").asText());

        byte[] binary = listener.awaitBinary();
        assertArrayEquals(new byte[] { 5, 6, 7 }, binary);
        JsonNode audioEnd = listener.awaitText(objectMapper);
        assertEquals("audio_end", audioEnd.path("event").asText());
        webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "done").join();
    }

    @Test
    void startTurnControlFrameResetsBufferBeforeEndTurn() throws Exception {
        voiceTestState.transcript.set("ok");
        voiceTestState.replyText.set("ok");
        voiceTestState.replyAudio.set(new byte[] { 1 });

        TestListener listener = new TestListener();
        WebSocket webSocket = connect(listener);
        listener.awaitText(objectMapper); // connected
        listener.awaitEvent(objectMapper, "jitter_config", 2);

        webSocket.sendBinary(ByteBuffer.wrap(new byte[] { 1, 2 }), true).join();
        webSocket.sendText("{\"v\":1,\"event\":\"start_turn\"}", true).join();
        webSocket.sendBinary(ByteBuffer.wrap(new byte[] { 9, 9, 9 }), true).join();
        webSocket.sendText("{\"v\":1,\"event\":\"end_turn\"}", true).join();

        listener.awaitText(objectMapper); // processing
        listener.awaitText(objectMapper); // transcript
        listener.awaitText(objectMapper); // assistant_text
        listener.awaitBinary(); // reply audio

        assertNotNull(voiceTestState.lastAudio.get());
        assertTrue(Arrays.equals(new byte[] { 9, 9, 9 }, voiceTestState.lastAudio.get()));
        webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "done").join();
    }

    @Test
    void invalidTokenEmitsErrorAndClosesConnection() throws Exception {
        TestListener listener = new TestListener();
        WebSocket webSocket = connect("bad-token", listener);

        JsonNode error = listener.awaitText(objectMapper);
        assertEquals(1, error.path("v").asInt());
        assertEquals("error", error.path("event").asText());
        assertEquals("Authentication failed for voice session", error.path("message").asText());
        webSocket.abort();
    }

    @Test
    void emitsPartialTranscriptEventsForLongTranscript() throws Exception {
        voiceTestState.transcript.set("this is a long transcript");
        voiceTestState.replyText.set("this is a longer assistant response");
        TestListener listener = new TestListener();
        WebSocket webSocket = connect(listener);
        listener.awaitText(objectMapper); // connected
        listener.awaitEvent(objectMapper, "jitter_config", 2);

        webSocket.sendText("{\"v\":1,\"event\":\"start_turn\"}", true).join();
        webSocket.sendBinary(ByteBuffer.wrap(new byte[] { 1, 2, 3 }), true).join();
        webSocket.sendText("{\"v\":1,\"event\":\"end_turn\"}", true).join();

        List<JsonNode> events = listener.awaitTextEventsUntil(objectMapper, "audio_end", 12);
        long partials = events.stream()
                .filter(e -> "partial_transcript".equals(e.path("event").asText()))
                .count();
        assertTrue(partials > 0);
        assertTrue(events.stream().anyMatch(e -> "assistant_partial".equals(e.path("event").asText())));
        assertTrue(events.stream().anyMatch(e -> "audio_end".equals(e.path("event").asText())));
        webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "done").join();
    }

    @Test
    void actuatorExposesVoiceConnectionMetric() throws Exception {
        TestListener listener = new TestListener();
        WebSocket webSocket = connect(listener);
        listener.awaitText(objectMapper); // connected
        listener.awaitEvent(objectMapper, "jitter_config", 2);
        webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "done").join();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/actuator/metrics/voice.ws.connections.opened"))
                .GET()
                .build();
        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, response.statusCode());
        JsonNode payload = objectMapper.readTree(response.body());
        assertEquals("voice.ws.connections.opened", payload.path("name").asText());
        assertTrue(payload.path("measurements").isArray());
        assertTrue(payload.path("measurements").size() > 0);
    }

    private WebSocket connect(TestListener listener) {
        return connect("test-token", listener);
    }

    private WebSocket connect(String token, TestListener listener) {
        URI uri = URI.create("ws://localhost:" + port + "/ws/voice?token=" + token);
        return HttpClient.newHttpClient()
                .newWebSocketBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .buildAsync(uri, listener)
                .join();
    }

    private static class TestListener implements WebSocket.Listener {
        private final BlockingQueue<String> textMessages = new LinkedBlockingQueue<>();
        private final BlockingQueue<byte[]> binaryMessages = new LinkedBlockingQueue<>();
        private final StringBuilder textBuffer = new StringBuilder();

        @Override
        public CompletableFuture<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
            textBuffer.append(data);
            if (last) {
                textMessages.offer(textBuffer.toString());
                textBuffer.setLength(0);
            }
            webSocket.request(1);
            return CompletableFuture.completedFuture(null);
        }

        @Override
        public CompletableFuture<?> onBinary(WebSocket webSocket, ByteBuffer data, boolean last) {
            byte[] bytes = new byte[data.remaining()];
            data.get(bytes);
            binaryMessages.offer(bytes);
            webSocket.request(1);
            return CompletableFuture.completedFuture(null);
        }

        @Override
        public void onOpen(WebSocket webSocket) {
            webSocket.request(1);
            WebSocket.Listener.super.onOpen(webSocket);
        }

        JsonNode awaitText(ObjectMapper objectMapper) throws Exception {
            String payload = textMessages.poll(5, TimeUnit.SECONDS);
            if (payload == null) {
                throw new IllegalStateException("Timed out waiting for text message");
            }
            return objectMapper.readTree(payload);
        }

        byte[] awaitBinary() throws Exception {
            byte[] payload = binaryMessages.poll(5, TimeUnit.SECONDS);
            if (payload == null) {
                throw new IllegalStateException("Timed out waiting for binary message");
            }
            return payload;
        }

        List<JsonNode> awaitTextEvents(ObjectMapper objectMapper, int count) throws Exception {
            java.util.ArrayList<JsonNode> events = new java.util.ArrayList<>();
            for (int i = 0; i < count; i++) {
                events.add(awaitText(objectMapper));
            }
            return events;
        }

        List<JsonNode> awaitTextEventsUntil(ObjectMapper objectMapper, String targetEvent, int maxEvents) throws Exception {
            java.util.ArrayList<JsonNode> events = new java.util.ArrayList<>();
            for (int i = 0; i < maxEvents; i++) {
                JsonNode event = awaitText(objectMapper);
                events.add(event);
                if (targetEvent.equals(event.path("event").asText())) {
                    break;
                }
            }
            return events;
        }

        JsonNode awaitEvent(ObjectMapper objectMapper, String targetEvent, int maxEvents) throws Exception {
            for (int i = 0; i < maxEvents; i++) {
                JsonNode event = awaitText(objectMapper);
                if (targetEvent.equals(event.path("event").asText())) {
                    return event;
                }
            }
            throw new IllegalStateException("Timed out waiting for event " + targetEvent);
        }

    }

    static class VoiceTestState {
        final AtomicReference<String> transcript = new AtomicReference<>("hello");
        final AtomicReference<String> replyText = new AtomicReference<>("Hi from AI");
        final AtomicReference<byte[]> replyAudio = new AtomicReference<>(new byte[] { 5, 6, 7 });
        final AtomicReference<byte[]> lastAudio = new AtomicReference<>();
    }
}
