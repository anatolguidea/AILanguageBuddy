package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.service.ReactiveVoiceServiceClient;
import com.example.ailanguagebuddy.service.voice.ProcessVoiceTurnUseCase;
import com.example.ailanguagebuddy.service.voice.GeneratePartialTranscriptUseCase;
import com.example.ailanguagebuddy.service.voice.TextToSpeechPort;
import com.example.ailanguagebuddy.service.voice.VoiceTurnException;
import com.example.ailanguagebuddy.service.voice.protocol.VoiceControlMessage;
import com.example.ailanguagebuddy.service.voice.protocol.VoiceEventMessage;
import com.example.ailanguagebuddy.service.voice.protocol.VoiceEventType;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.Timer;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;
import org.springframework.web.util.UriComponentsBuilder;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.nio.ByteBuffer;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

@Component
public class VoiceWebSocketHandler extends BinaryWebSocketHandler {
    private static final int PROTOCOL_VERSION = 1;
    private static final int MAX_TURN_AUDIO_BYTES = 2_000_000;
    private static final long HOUSEKEEPING_INTERVAL_MS = 5_000;
    private static final long LISTENING_TIMEOUT_MS = 20_000;
    private static final long STALE_SESSION_TIMEOUT_MS = 300_000;
    private static final int AUDIO_CHUNK_SIZE_BYTES = 8_192;
    private static final int MIN_AUDIO_BYTES_FOR_PARTIAL = 32_000;
    private static final long PARTIAL_MIN_INTERVAL_MS = 1_200;
    private static final int MAX_TTS_SEGMENT_CHARS = 180;
    private static final int MAX_TTS_SEGMENTS = 8;
    private static final int DEFAULT_PREBUFFER_CHUNKS = 2;
    private static final int DEFAULT_PREBUFFER_BYTES = 12 * 1024;
    private static final int DEFAULT_QUEUE_HIGH_WATERMARK_BYTES = 2 * 1024 * 1024;
    private static final int DEFAULT_QUEUE_TRIM_TARGET_BYTES = 1536 * 1024;
    private static final Duration TTS_STREAM_TIMEOUT = Duration.ofSeconds(60);
    private static final long FIRST_AUDIO_CHUNK_DELAY_MS = 100L;

    private enum SessionState {
        CONNECTED, LISTENING, PROCESSING
    }

    private final ProcessVoiceTurnUseCase processVoiceTurnUseCase;
    private final GeneratePartialTranscriptUseCase generatePartialTranscriptUseCase;
    private final TextToSpeechPort textToSpeechPort;
    private final JwtDecoder jwtDecoder;
    private final ObjectMapper objectMapper;
    private final MeterRegistry meterRegistry;
    private final Counter connectionCounter;
    private final Counter authFailureCounter;
    private final Counter turnStartedCounter;
    private final Counter turnCompletedCounter;
    private final Counter turnFailedCounter;
    private final Counter partialGeneratedCounter;
    private final Counter audioChunkSentCounter;
    private final DistributionSummary turnInputAudioBytesSummary;
    private final DistributionSummary turnOutputAudioBytesSummary;
    private final Timer turnProcessingTimer;

    public VoiceWebSocketHandler(ProcessVoiceTurnUseCase processVoiceTurnUseCase,
            GeneratePartialTranscriptUseCase generatePartialTranscriptUseCase,
            TextToSpeechPort textToSpeechPort,
            JwtDecoder jwtDecoder,
            ObjectMapper objectMapper) {
        this(processVoiceTurnUseCase, generatePartialTranscriptUseCase, textToSpeechPort, jwtDecoder, objectMapper,
                Metrics.globalRegistry);
    }

    @Autowired
    public VoiceWebSocketHandler(ProcessVoiceTurnUseCase processVoiceTurnUseCase,
            GeneratePartialTranscriptUseCase generatePartialTranscriptUseCase,
            TextToSpeechPort textToSpeechPort,
            JwtDecoder jwtDecoder,
            ObjectMapper objectMapper,
            MeterRegistry meterRegistry) {
        this.processVoiceTurnUseCase = processVoiceTurnUseCase;
        this.generatePartialTranscriptUseCase = generatePartialTranscriptUseCase;
        this.textToSpeechPort = textToSpeechPort;
        this.jwtDecoder = jwtDecoder;
        this.objectMapper = objectMapper;
        this.meterRegistry = meterRegistry;
        this.connectionCounter = Counter.builder("voice.ws.connections.opened")
                .description("Number of established voice websocket connections")
                .register(meterRegistry);
        this.authFailureCounter = Counter.builder("voice.ws.connections.auth_failures")
                .description("Number of rejected voice websocket connections due to authentication")
                .register(meterRegistry);
        this.turnStartedCounter = Counter.builder("voice.turn.started")
                .description("Number of started voice turns")
                .register(meterRegistry);
        this.turnCompletedCounter = Counter.builder("voice.turn.completed")
                .description("Number of successfully completed voice turns")
                .register(meterRegistry);
        this.turnFailedCounter = Counter.builder("voice.turn.failed")
                .description("Number of failed voice turns")
                .register(meterRegistry);
        this.partialGeneratedCounter = Counter.builder("voice.partial_transcript.generated")
                .description("Number of partial transcript events generated")
                .register(meterRegistry);
        this.audioChunkSentCounter = Counter.builder("voice.audio.chunks.sent")
                .description("Number of outgoing audio binary chunks sent")
                .register(meterRegistry);
        this.turnInputAudioBytesSummary = DistributionSummary.builder("voice.turn.audio.input.bytes")
                .description("Distribution of audio bytes received for processed voice turns")
                .baseUnit("bytes")
                .register(meterRegistry);
        this.turnOutputAudioBytesSummary = DistributionSummary.builder("voice.turn.audio.output.bytes")
                .description("Distribution of audio bytes generated for assistant voice turns")
                .baseUnit("bytes")
                .register(meterRegistry);
        this.turnProcessingTimer = Timer.builder("voice.turn.processing.duration")
                .description("End-to-end duration for processing one voice turn")
                .register(meterRegistry);
    }

    // Per-session audio buffer for push-to-talk turns.
    private final ConcurrentHashMap<String, java.io.ByteArrayOutputStream> sessionAudioBuffers = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, SessionState> sessionStates = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, WebSocketSession> sessionRegistry = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Long> sessionLastActivityAt = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Long> sessionLastPartialAt = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> sessionLastPartialText = new ConcurrentHashMap<>();
    private final ScheduledExecutorService housekeepingExecutor = Executors.newSingleThreadScheduledExecutor();
    private final ExecutorService voiceProcessingExecutor = Executors.newVirtualThreadPerTaskExecutor();

    @PostConstruct
    public void startHousekeeping() {
        housekeepingExecutor.scheduleAtFixedRate(this::runHousekeepingSafely,
                HOUSEKEEPING_INTERVAL_MS,
                HOUSEKEEPING_INTERVAL_MS,
                TimeUnit.MILLISECONDS);
    }

    @PreDestroy
    public void shutdownHousekeeping() {
        housekeepingExecutor.shutdownNow();
        voiceProcessingExecutor.shutdownNow();
    }

    private void runHousekeepingSafely() {
        try {
            runHousekeeping();
        } catch (Exception e) {
            System.err.println("Voice housekeeping error: " + e.getMessage());
        }
    }

    private void runHousekeeping() {
        long now = System.currentTimeMillis();
        List<String> ids = new ArrayList<>(sessionRegistry.keySet());
        for (String sessionId : ids) {
            Long lastActivity = sessionLastActivityAt.get(sessionId);
            if (lastActivity == null) {
                continue;
            }

            WebSocketSession session = sessionRegistry.get(sessionId);
            if (session == null) {
                cleanupSessionById(sessionId);
                continue;
            }

            long idleMillis = now - lastActivity;
            SessionState state = sessionStates.getOrDefault(sessionId, SessionState.CONNECTED);

            if (state == SessionState.LISTENING && idleMillis > LISTENING_TIMEOUT_MS) {
                java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(sessionId);
                if (buffer != null) {
                    buffer.reset();
                }
                sessionStates.put(sessionId, SessionState.CONNECTED);
                sessionLastActivityAt.put(sessionId, now);
                sendError(session, "turn_timeout", "No speech activity detected before turn timeout");
                continue;
            }

            if (idleMillis > STALE_SESSION_TIMEOUT_MS) {
                try {
                    if (session.isOpen()) {
                        session.close(CloseStatus.SESSION_NOT_RELIABLE.withReason("Stale voice session"));
                    }
                } catch (Exception ignored) {
                } finally {
                    cleanupSessionById(sessionId);
                }
            }
        }
    }

    private void touchSession(String sessionId) {
        sessionLastActivityAt.put(sessionId, System.currentTimeMillis());
    }

    private void cleanupSessionById(String sessionId) {
        sessionAudioBuffers.remove(sessionId);
        sessionStates.remove(sessionId);
        sessionRegistry.remove(sessionId);
        sessionLastActivityAt.remove(sessionId);
        sessionLastPartialAt.remove(sessionId);
        sessionLastPartialText.remove(sessionId);
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("Voice WS Connected: " + session.getId());
        connectionCounter.increment();

        String token = UriComponentsBuilder.fromUri(session.getUri()).build().getQueryParams().getFirst("token");
        UUID userId = authenticateUser(token);
        if (userId == null) {
            authFailureCounter.increment();
            sendEvent(session, VoiceEventType.ERROR, "Authentication failed for voice session");
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("Missing or invalid token"));
            return;
        }

        session.getAttributes().put("userId", userId);
        System.out.println("Voice WS Authenticated user: " + userId);

        sessionAudioBuffers.put(session.getId(), new java.io.ByteArrayOutputStream());
        sessionStates.put(session.getId(), SessionState.CONNECTED);
        sessionRegistry.put(session.getId(), session);
        touchSession(session.getId());
        sendEvent(session, VoiceEventType.CONNECTED, "Voice socket ready");
        sendJitterConfig(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        cleanupSessionById(session.getId());
    }

    private UUID authenticateUser(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        try {
            Jwt jwt = jwtDecoder.decode(token);
            String subject = jwt.getSubject();
            if (subject == null || subject.isBlank()) {
                return null;
            }
            return UUID.fromString(subject);
        } catch (Exception e) {
            System.err.println("Voice WS token validation failed: " + e.getMessage());
            return null;
        }
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) {
        try {
            java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(session.getId());
            if (buffer != null) {
                SessionState state = sessionStates.get(session.getId());
                if (state == null) {
                    sendError(session, "session_not_initialized", "Voice session state is not initialized");
                    return;
                }
                // Backward compatibility for clients that stream audio before explicit
                // start_turn.
                if (state == SessionState.CONNECTED) {
                    sessionStates.put(session.getId(), SessionState.LISTENING);
                    turnStartedCounter.increment();
                } else if (state != SessionState.LISTENING) {
                    sendError(session, "invalid_state", "Cannot accept audio in state " + state.name().toLowerCase());
                    return;
                }
                ByteBuffer payload = message.getPayload().asReadOnlyBuffer();
                byte[] bytes = new byte[payload.remaining()];
                if (buffer.size() + bytes.length > MAX_TURN_AUDIO_BYTES) {
                    buffer.reset();
                    sessionStates.put(session.getId(), SessionState.CONNECTED);
                    sendError(session, "audio_too_large", "Audio turn exceeded maximum supported size");
                    return;
                }
                payload.get(bytes);
                buffer.write(bytes);
                touchSession(session.getId());
                maybeEmitIncrementalPartial(session, buffer);
            }
        } catch (Exception e) {
            System.err.println("Error buffering audio: " + e.getMessage());
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        String payload = message.getPayload();
        if ("EOS".equalsIgnoreCase(payload)) {
            processBufferedAudio(session);
            return;
        }

        try {
            VoiceControlMessage control = objectMapper.readValue(payload, VoiceControlMessage.class);
            VoiceEventType controlEvent = VoiceEventType.fromWireValue(control.event());
            if (VoiceEventType.START_TURN.equals(controlEvent)) {
                resetBuffer(session);
                sessionStates.put(session.getId(), SessionState.LISTENING);
                touchSession(session.getId());
                turnStartedCounter.increment();
            } else if (VoiceEventType.END_TURN.equals(controlEvent)) {
                SessionState state = sessionStates.get(session.getId());
                if (state != SessionState.LISTENING) {
                    sendError(session, "invalid_state",
                            "Cannot end turn in state " + (state == null ? "unknown" : state.name().toLowerCase()));
                    return;
                }
                sessionStates.put(session.getId(), SessionState.PROCESSING);
                touchSession(session.getId());
                processBufferedAudio(session);
            }
        } catch (Exception ignored) {
            // Ignore non-JSON control messages for backward compatibility.
        }
    }

    private void resetBuffer(WebSocketSession session) {
        java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(session.getId());
        if (buffer != null) {
            buffer.reset();
        }
    }

    private void processBufferedAudio(WebSocketSession session) {
        // Dispatch to a virtual thread so the WebSocket thread is free immediately.
        CompletableFuture.runAsync(() -> processBufferedAudioInternal(session), voiceProcessingExecutor)
                .exceptionally(ex -> {
                    System.err.println("Async voice processing failed: " + ex.getMessage());
                    sendError(session, "voice_turn_failed", ex.getMessage());
                    sessionStates.put(session.getId(), SessionState.CONNECTED);
                    return null;
                });
    }

    private void processBufferedAudioInternal(WebSocketSession session) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(session.getId());
            if (buffer == null || buffer.size() == 0) {
                sendError(session, "empty_audio", "No audio received for this turn");
                sessionStates.put(session.getId(), SessionState.CONNECTED);
                return;
            }

            byte[] completeAudio = buffer.toByteArray();
            buffer.reset();
            turnInputAudioBytesSummary.record(completeAudio.length);

            System.out.println("Processing audio turn: " + completeAudio.length + " bytes");
            UUID userId = (UUID) session.getAttributes().get("userId");
            sendEvent(session, VoiceEventType.PROCESSING, "Transcribing and generating answer");

            if (processVoiceTurnUseCase.isStreamingAvailable()) {
                processStreamingPipeline(session, completeAudio, userId);
            } else {
                processSequentialPipeline(session, completeAudio, userId);
            }

            turnCompletedCounter.increment();
        } catch (VoiceTurnException e) {
            turnFailedCounter.increment();
            sendError(session, e.code(), e.getMessage());
        } catch (Exception e) {
            turnFailedCounter.increment();
            System.err.println("Error processing voice turn: " + e.getMessage());
            e.printStackTrace();
            sendError(session, "voice_turn_failed", e.getMessage());
        } finally {
            sample.stop(turnProcessingTimer);
            sessionStates.put(session.getId(), SessionState.CONNECTED);
            touchSession(session.getId());
        }
    }

    // ─── Streaming pipeline: STT → filler → LLM(stream) → TTS per sentence ───

    private void processStreamingPipeline(WebSocketSession session, byte[] audio, UUID userId) throws Exception {
        final int[] outputBytes = { 0 };
        final StringBuilder progressiveText = new StringBuilder();
        // Arm the client-side streaming player before first binary audio chunk arrives.
        sendEvent(session, VoiceEventType.ASSISTANT_TEXT, "");

        ProcessVoiceTurnUseCase.TurnTextResult result = processVoiceTurnUseCase.executeStreaming(
                audio, userId, (sentence) -> {
                    try {
                        // 1. Emit real assistant_partial with progressive text
                        if (progressiveText.length() > 0) {
                            progressiveText.append(' ');
                        }
                        progressiveText.append(sentence);
                        sendEvent(session, VoiceEventType.ASSISTANT_PARTIAL, progressiveText.toString());

                        // 2. TTS this sentence immediately and stream audio.
                        outputBytes[0] += streamRealtimeSentenceAudio(session, sentence);
                    } catch (Exception e) {
                        System.err.println("Error in streaming sentence callback: " + e.getMessage());
                    }
                });

        // Emit transcript + full text events
        emitFallbackPartialTranscriptEvents(session, result.transcript());
        sendEvent(session, VoiceEventType.TRANSCRIPT, result.transcript());

        if (outputBytes[0] == 0) {
            // Streaming sentence path produced no bytes; send full text + fallback segmented TTS.
            sendEvent(session, VoiceEventType.ASSISTANT_TEXT, result.replyText());
            // Fallback: TTS the full reply if per-sentence TTS failed
            int fallbackBytes = streamSegmentedReplyAudio(session, result.replyText());
            turnOutputAudioBytesSummary.record(fallbackBytes);
        } else {
            turnOutputAudioBytesSummary.record(outputBytes[0]);
        }

        if (session.isOpen()) {
            sendEvent(session, VoiceEventType.AUDIO_END, "Audio stream complete");
        }
    }

    // ─── Sequential pipeline (fallback): STT → full LLM → TTS segments ───

    private void processSequentialPipeline(WebSocketSession session, byte[] audio, UUID userId) throws Exception {
        ProcessVoiceTurnUseCase.TurnTextResult result = processVoiceTurnUseCase.executeTextOnly(audio, userId);
        emitFallbackPartialTranscriptEvents(session, result.transcript());
        sendEvent(session, VoiceEventType.TRANSCRIPT, result.transcript());
        emitAssistantPartialEvents(session, result.replyText());
        sendEvent(session, VoiceEventType.ASSISTANT_TEXT, result.replyText());

        int outputBytes = 0;
        if (session.isOpen()) {
            outputBytes = streamSegmentedReplyAudio(session, result.replyText());
            sendEvent(session, VoiceEventType.AUDIO_END, "Audio stream complete");
        }
        turnOutputAudioBytesSummary.record(outputBytes);
    }

    private void emitFallbackPartialTranscriptEvents(WebSocketSession session, String transcript) throws Exception {
        if (transcript == null) {
            return;
        }
        String trimmed = transcript.trim();
        if (trimmed.isEmpty()) {
            return;
        }
        String[] words = trimmed.split("\\s+");
        if (words.length < 3) {
            return;
        }
        int step = Math.max(1, words.length / 3);
        StringBuilder progressive = new StringBuilder();
        for (int i = 0; i < words.length; i++) {
            if (progressive.length() > 0) {
                progressive.append(' ');
            }
            progressive.append(words[i]);
            if ((i + 1) % step == 0 && i < words.length - 1) {
                maybeSendPartialTranscript(session, progressive.toString());
            }
        }
    }

    private void maybeEmitIncrementalPartial(WebSocketSession session, java.io.ByteArrayOutputStream buffer)
            throws Exception {
        String sessionId = session.getId();
        if (sessionStates.get(sessionId) != SessionState.LISTENING) {
            return;
        }
        if (buffer.size() < MIN_AUDIO_BYTES_FOR_PARTIAL) {
            return;
        }
        long now = System.currentTimeMillis();
        long lastAt = sessionLastPartialAt.getOrDefault(sessionId, 0L);
        if (now - lastAt < PARTIAL_MIN_INTERVAL_MS) {
            return;
        }
        sessionLastPartialAt.put(sessionId, now);
        byte[] snapshot = buffer.toByteArray();
        String partial = generatePartialTranscriptUseCase.execute(snapshot);
        maybeSendPartialTranscript(session, partial);
    }

    private void maybeSendPartialTranscript(WebSocketSession session, String partial) throws Exception {
        if (partial == null || partial.isBlank()) {
            return;
        }
        String sessionId = session.getId();
        String normalized = partial.trim();
        String previous = sessionLastPartialText.get(sessionId);
        if (normalized.equals(previous)) {
            return;
        }
        sessionLastPartialText.put(sessionId, normalized);
        partialGeneratedCounter.increment();
        sendEvent(session, VoiceEventType.PARTIAL_TRANSCRIPT, normalized);
    }

    private void emitAssistantPartialEvents(WebSocketSession session, String replyText) throws Exception {
        if (replyText == null) {
            return;
        }
        String trimmed = replyText.trim();
        if (trimmed.isEmpty()) {
            return;
        }
        String[] words = trimmed.split("\\s+");
        if (words.length < 4) {
            return;
        }
        int step = Math.max(1, words.length / 3);
        StringBuilder progressive = new StringBuilder();
        for (int i = 0; i < words.length; i++) {
            if (progressive.length() > 0) {
                progressive.append(' ');
            }
            progressive.append(words[i]);
            if ((i + 1) % step == 0 && i < words.length - 1) {
                sendEvent(session, VoiceEventType.ASSISTANT_PARTIAL, progressive.toString());
            }
        }
    }

    private int streamSegmentedReplyAudio(WebSocketSession session, String replyText) throws Exception {
        int totalBytes = 0;
        for (String segment : splitReplyForTts(replyText)) {
            byte[] segmentAudio = textToSpeechPort.synthesize(segment);
            if (segmentAudio == null || segmentAudio.length == 0) {
                continue;
            }
            totalBytes += segmentAudio.length;
            sendAudioChunks(session, segmentAudio);
        }
        if (totalBytes == 0) {
            throw new VoiceTurnException("tts_failed", "TTS returned empty audio for segmented reply");
        }
        return totalBytes;
    }

    private List<String> splitReplyForTts(String replyText) {
        if (replyText == null || replyText.isBlank()) {
            return List.of();
        }
        String[] parts = replyText.trim().split("(?<=[.!?])\\s+");
        List<String> segments = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        for (String part : parts) {
            String sentence = part.trim();
            if (sentence.isEmpty()) {
                continue;
            }
            int projected = current.length() + (current.length() == 0 ? 0 : 1) + sentence.length();
            if (projected > MAX_TTS_SEGMENT_CHARS && current.length() > 0) {
                segments.add(current.toString());
                current.setLength(0);
            }
            if (current.length() > 0) {
                current.append(' ');
            }
            current.append(sentence);
            if (segments.size() >= MAX_TTS_SEGMENTS) {
                break;
            }
        }
        if (current.length() > 0 && segments.size() < MAX_TTS_SEGMENTS) {
            segments.add(current.toString());
        }
        if (segments.isEmpty()) {
            String fallback = replyText.trim();
            if (fallback.length() > MAX_TTS_SEGMENT_CHARS) {
                fallback = fallback.substring(0, MAX_TTS_SEGMENT_CHARS);
            }
            return List.of(fallback);
        }
        return segments;
    }

    private int streamRealtimeSentenceAudio(WebSocketSession session, String sentence) throws Exception {
        if (!session.isOpen() || sentence == null || sentence.isBlank()) {
            return 0;
        }
        if (textToSpeechPort instanceof ReactiveVoiceServiceClient reactiveVoiceClient) {
            return streamRealtimeFromVoiceService(session, reactiveVoiceClient, sentence);
        }
        byte[] sentenceAudio = textToSpeechPort.synthesize(sentence);
        if (sentenceAudio == null || sentenceAudio.length == 0) {
            return 0;
        }
        sendAudioChunks(session, sentenceAudio);
        return sentenceAudio.length;
    }

    private int streamRealtimeFromVoiceService(
            WebSocketSession session,
            ReactiveVoiceServiceClient reactiveVoiceClient,
            String sentence) {
        AtomicInteger sentBytes = new AtomicInteger();
        AtomicBoolean firstChunk = new AtomicBoolean(true);

        reactiveVoiceClient.synthesizeStreamChunksAsync(sentence, "en")
                .doOnNext(chunk -> {
                    if (chunk.length == 0 || !session.isOpen()) {
                        return;
                    }
                    try {
                        maybeDelayBeforeFirstChunk(firstChunk);
                        session.sendMessage(new BinaryMessage(chunk));
                        audioChunkSentCounter.increment();
                        sentBytes.addAndGet(chunk.length);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                })
                .blockLast(TTS_STREAM_TIMEOUT);

        return sentBytes.get();
    }

    private void sendAudioChunks(WebSocketSession session, byte[] audioBytes) throws Exception {
        if (audioBytes == null || audioBytes.length == 0 || !session.isOpen()) {
            return;
        }

        int chunkCount = 0;
        boolean firstChunk = true;
        for (int offset = 0; offset < audioBytes.length; offset += AUDIO_CHUNK_SIZE_BYTES) {
            int end = Math.min(audioBytes.length, offset + AUDIO_CHUNK_SIZE_BYTES);
            byte[] chunk = new byte[end - offset];
            System.arraycopy(audioBytes, offset, chunk, 0, chunk.length);
            if (firstChunk) {
                Thread.sleep(FIRST_AUDIO_CHUNK_DELAY_MS);
                firstChunk = false;
            }
            session.sendMessage(new BinaryMessage(chunk));
            audioChunkSentCounter.increment();
            chunkCount++;
            if (chunkCount <= 3) {
                System.out.println("[audio-proxy] Sent chunk #" + chunkCount
                        + ": " + chunk.length + " bytes");
            }
        }
        System.out.println("[audio-proxy] Total: " + chunkCount + " chunks sent");
    }

    private void maybeDelayBeforeFirstChunk(AtomicBoolean firstChunk) throws InterruptedException {
        if (firstChunk.compareAndSet(true, false)) {
            Thread.sleep(FIRST_AUDIO_CHUNK_DELAY_MS);
        }
    }

    private void sendError(WebSocketSession session, String code, String message) {
        try {
            Counter.builder("voice.ws.errors")
                    .description("Voice websocket structured errors grouped by code")
                    .tag("code", code == null || code.isBlank() ? "unknown" : code)
                    .register(meterRegistry)
                    .increment();
            sendEvent(session, VoiceEventType.ERROR, message, code);
        } catch (Exception ignored) {
        }
    }

    private void sendEvent(WebSocketSession session, VoiceEventType event, String message) throws Exception {
        sendEvent(session, event, message, null, null);
    }

    private void sendEvent(WebSocketSession session, VoiceEventType event, String message, String code)
            throws Exception {
        sendEvent(session, event, message, code, null);
    }

    private void sendEvent(WebSocketSession session, VoiceEventType event, String message, String code,
            Map<String, Object> data)
            throws Exception {
        if (!session.isOpen()) {
            return;
        }
        String safeMessage = message == null ? "Unknown voice error" : message;
        VoiceEventMessage payload = new VoiceEventMessage(PROTOCOL_VERSION, event.wireValue(), safeMessage, code, data);
        try {
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(payload)));
        } catch (JsonProcessingException e) {
            session.sendMessage(
                    new TextMessage("{\"event\":\"error\",\"message\":\"Failed to serialize voice event\"}"));
        }
    }

    private void sendJitterConfig(WebSocketSession session) throws Exception {
        sendEvent(
                session,
                VoiceEventType.JITTER_CONFIG,
                "Playback jitter policy",
                null,
                Map.of(
                        "prebufferChunks", DEFAULT_PREBUFFER_CHUNKS,
                        "prebufferBytes", DEFAULT_PREBUFFER_BYTES,
                        "queueHighWatermarkBytes", DEFAULT_QUEUE_HIGH_WATERMARK_BYTES,
                        "queueTrimTargetBytes", DEFAULT_QUEUE_TRIM_TARGET_BYTES));
    }
}
