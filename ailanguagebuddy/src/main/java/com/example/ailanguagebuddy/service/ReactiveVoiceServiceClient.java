package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.service.voice.SpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.PartialSpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.TextToSpeechPort;
import com.example.ailanguagebuddy.service.voice.VoiceTurnException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyExtractors;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.io.ByteArrayOutputStream;
import java.time.Duration;

/**
 * Non-blocking voice-service client using Spring WebClient (Reactor/Netty).
 * <p>
 * Implements the same ports as {@link VoiceServiceClient} so it can be swapped
 * in transparently via {@code @Primary}. The blocking bridge methods
 * ({@code transcribe}, {@code synthesize}) delegate to the reactive core with
 * {@code .block()}, keeping backward compatibility with the synchronous
 * processing pipeline.
 * <p>
 * For the async/streaming pipeline, callers should use the {@code *Async}
 * methods directly, which return {@code Mono<T>}.
 */
@Service
@Primary
public class ReactiveVoiceServiceClient implements SpeechToTextPort, PartialSpeechToTextPort, TextToSpeechPort {

    private static final Logger log = LoggerFactory.getLogger(ReactiveVoiceServiceClient.class);
    private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(60);
    private static final MediaType AUDIO_WAV = MediaType.parseMediaType("audio/wav");

    private final WebClient webClient;
    private final int sttSampleRate;

    public ReactiveVoiceServiceClient(
            WebClient.Builder builder,
            @Value("${voice-service.base-url:http://localhost:8000}") String baseUrl,
            @Value("${voice.stt.sample-rate:16000}") int sttSampleRate) {
        this.webClient = builder
                .baseUrl(baseUrl)
                .codecs(cfg -> cfg.defaultCodecs().maxInMemorySize(4 * 1024 * 1024)) // 4 MB
                .build();
        this.sttSampleRate = sttSampleRate;
        log.info("ReactiveVoiceServiceClient initialized → {}", baseUrl);
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Reactive API (preferred for streaming pipeline)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /**
     * Non-blocking STT call → {@code Mono<String>}.
     */
    public Mono<String> transcribeAsync(byte[] audioData) {
        return transcribeInternalAsync(audioData, "/transcribe");
    }

    /**
     * Non-blocking partial STT → {@code Mono<String>}.
     */
    public Mono<String> transcribePartialAsync(byte[] audioData) {
        return transcribeInternalAsync(audioData, "/transcribe/partial");
    }

    /**
     * Non-blocking TTS call → {@code Mono<byte[]>}.
     */
    public Mono<byte[]> synthesizeAsync(String text) {
        return synthesizeAsync(text, "en");
    }

    /**
     * Non-blocking multilingual TTS → {@code Mono<byte[]>}.
     * <p>
     * Uses {@code DataBufferUtils.join()} to collect raw bytes from the voice
     * service without any codec/charset interference — critical for binary audio
     * integrity.
     */
    public Mono<byte[]> synthesizeAsync(String text, String language) {
        return synthesizeStreamChunksAsync(text, language)
                .reduce(new ByteArrayOutputStream(), (out, chunk) -> {
                    out.write(chunk, 0, chunk.length);
                    return out;
                })
                .map(ByteArrayOutputStream::toByteArray)
                .timeout(DEFAULT_TIMEOUT)
                .doOnError(e -> log.error("Reactive TTS failed: {}", e.getMessage()));
    }

    /**
     * Non-blocking multilingual TTS stream → {@code Flux<byte[]>} chunks.
     * Chunks are emitted as soon as the voice-service flushes them.
     */
    public Flux<byte[]> synthesizeStreamChunksAsync(String text, String language) {
        record SpeakRequest(String text, String language) {
        }

        return webClient.post()
                .uri("/synthesize/raw")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(AUDIO_WAV)
                .bodyValue(new SpeakRequest(text, language))
                .exchangeToFlux(response -> {
                    if (!response.statusCode().is2xxSuccessful()) {
                        return response.createException().flatMapMany(Flux::error);
                    }
                    return response.body(BodyExtractors.toDataBuffers())
                            .map(this::toBytes);
                })
                .doOnError(e -> log.error("Reactive TTS stream failed: {}", e.getMessage()));
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Blocking bridge (backward compatibility with sync pipeline)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    @Override
    public String transcribe(byte[] audioData) {
        try {
            String text = transcribeAsync(audioData).block(DEFAULT_TIMEOUT);
            if (text == null || text.isBlank()) {
                throw new VoiceTurnException("stt_unavailable", "Reactive STT returned empty");
            }
            return text;
        } catch (VoiceTurnException e) {
            throw e;
        } catch (Exception e) {
            throw new VoiceTurnException("stt_unavailable", "Reactive STT failed", e);
        }
    }

    @Override
    public String transcribePartial(byte[] audioData) {
        try {
            String text = transcribePartialAsync(audioData).block(DEFAULT_TIMEOUT);
            return text != null ? text : "";
        } catch (Exception e) {
            log.warn("Reactive partial STT failed: {}", e.getMessage());
            return "";
        }
    }

    @Override
    public byte[] synthesize(String text) {
        try {
            byte[] audio = synthesizeAsync(text).block(DEFAULT_TIMEOUT);
            if (audio == null || audio.length == 0) {
                throw new VoiceTurnException("tts_failed", "Reactive TTS returned empty audio");
            }
            return audio;
        } catch (VoiceTurnException e) {
            throw e;
        } catch (Exception e) {
            throw new VoiceTurnException("tts_failed", "Reactive TTS failed", e);
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Internal
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private Mono<String> transcribeInternalAsync(byte[] audioData, String path) {
        MultipartBodyBuilder bodyBuilder = new MultipartBodyBuilder();
        bodyBuilder.part("file", new ByteArrayResource(audioData) {
            @Override
            public String getFilename() {
                return "audio.wav";
            }
        }).contentType(MediaType.APPLICATION_OCTET_STREAM);
        bodyBuilder.part("sample_rate", Integer.toString(sttSampleRate));

        return webClient.post()
                .uri(path)
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(bodyBuilder.build()))
                .retrieve()
                .bodyToMono(TranscriptionResponse.class)
                .timeout(DEFAULT_TIMEOUT)
                .map(r -> r.text() != null ? r.text() : "")
                .doOnError(e -> log.error("Reactive STT [{}] failed: {}", path, e.getMessage()));
    }

    private byte[] toBytes(DataBuffer dataBuffer) {
        byte[] bytes = new byte[dataBuffer.readableByteCount()];
        dataBuffer.read(bytes);
        DataBufferUtils.release(dataBuffer);
        return bytes;
    }

    private record TranscriptionResponse(String text) {
    }
}
