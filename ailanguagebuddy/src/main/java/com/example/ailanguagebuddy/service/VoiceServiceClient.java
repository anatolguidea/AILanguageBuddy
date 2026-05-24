package com.example.ailanguagebuddy.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;

@Service
public class VoiceServiceClient {

    private static final Logger log = LoggerFactory.getLogger(VoiceServiceClient.class);
    private static final int CONNECT_TIMEOUT_MS = 1500;
    private static final int READ_TIMEOUT_MS = 4000;
    private static final int MAX_RETRIES = 2;
    private static final Duration RETRY_BACKOFF = Duration.ofMillis(200);
    private static final int CIRCUIT_BREAKER_THRESHOLD = 3;
    private static final Duration CIRCUIT_BREAKER_OPEN_DURATION = Duration.ofSeconds(20);

    private final RestClient restClient;
    private final AtomicInteger consecutiveFailures = new AtomicInteger(0);
    private volatile Instant circuitOpenUntil = Instant.EPOCH;

    public VoiceServiceClient(
            RestClient.Builder builder,
            @Value("${voice.service.url:http://localhost:8000}") String voiceServiceUrl) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(CONNECT_TIMEOUT_MS);
        requestFactory.setReadTimeout(READ_TIMEOUT_MS);
        this.restClient = builder
                .baseUrl(voiceServiceUrl)
                .requestFactory(requestFactory)
                .build();
    }

    public String transcribe(byte[] audioData, String languageCode) {
        return executeWithResilience("transcribe", () -> {
            ByteArrayResource resource = new ByteArrayResource(audioData) {
                @Override
                public String getFilename() {
                    return "audio.wav";
                }
            };

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", resource);

            String lang = (languageCode == null || languageCode.isBlank()) ? "en" : languageCode;
            TranscriptionResponse response = restClient.post()
                    .uri("/transcribe?language=" + lang)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(TranscriptionResponse.class);

            if (response == null || response.text() == null) {
                throw new VoiceServiceUnavailableException("STT response was empty");
            }
            return response.text();
        });
    }

    public byte[] synthesize(String text) {
        SpeakRequest request = new SpeakRequest(text, "en");
        return executeWithResilience("synthesize_raw", () -> restClient.post()
                .uri("/synthesize/raw")
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(byte[].class));
    }

    public InstantSpeech synthesizeInstant(String text, String language) {
        return executeWithResilience("synthesize_instant", () -> {
            SpeakRequest request = new SpeakRequest(text, language == null ? "en" : language);
            ResponseEntity<byte[]> response = restClient.post()
                    .uri("/synthesize/instant")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .toEntity(byte[].class);

            String codec = response.getHeaders().getFirst("X-Audio-Codec");
            String sampleRateHeader = response.getHeaders().getFirst("X-Audio-Sample-Rate");
            int sampleRate = 24000;
            if (sampleRateHeader != null) {
                try {
                    sampleRate = Integer.parseInt(sampleRateHeader);
                } catch (NumberFormatException ignored) {
                    sampleRate = 24000;
                }
            }
            MediaType mediaType = response.getHeaders().getContentType();
            return new InstantSpeech(
                    response.getBody() == null ? new byte[0] : response.getBody(),
                    codec == null ? "pcm16" : codec,
                    sampleRate,
                    mediaType == null ? MediaType.APPLICATION_OCTET_STREAM_VALUE : mediaType.toString());
        });
    }

    public void prewarm(String languageCode) {
        executeWithResilience("prewarm", () -> {
            String lang = (languageCode == null || languageCode.isBlank()) ? "en" : languageCode;
            restClient.post()
                    .uri("/prewarm")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(new PrewarmRequest(lang))
                    .retrieve()
                    .toBodilessEntity();
            return null;
        });
    }

    private <T> T executeWithResilience(String operation, Supplier<T> action) {
        if (Instant.now().isBefore(circuitOpenUntil)) {
            throw new VoiceServiceUnavailableException(
                    "Voice service temporarily unavailable (circuit breaker open)");
        }

        RuntimeException lastException = null;
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                T result = action.get();
                consecutiveFailures.set(0);
                circuitOpenUntil = Instant.EPOCH;
                return result;
            } catch (RuntimeException ex) {
                lastException = ex;
                if (attempt < MAX_RETRIES) {
                    sleepBackoff();
                }
            }
        }

        int failures = consecutiveFailures.incrementAndGet();
        if (failures >= CIRCUIT_BREAKER_THRESHOLD) {
            circuitOpenUntil = Instant.now().plus(CIRCUIT_BREAKER_OPEN_DURATION);
            log.warn("Voice client circuit breaker opened after {} failures", failures);
        }

        throw new VoiceServiceUnavailableException(
                "Voice service operation failed: " + operation,
                lastException);
    }

    private static void sleepBackoff() {
        try {
            Thread.sleep(RETRY_BACKOFF.toMillis());
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }

    public record TranscriptionResponse(String text) {
    }

    public record SpeakRequest(String text, String language) {
    }

    public record PrewarmRequest(String language) {
    }

    public record InstantSpeech(byte[] audioBytes, String codec, int sampleRate, String mediaType) {
    }
}
