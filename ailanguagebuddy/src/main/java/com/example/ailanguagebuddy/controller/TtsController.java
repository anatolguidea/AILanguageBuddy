package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.service.VoiceServiceClient;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/tts")
public class TtsController {

    private final VoiceServiceClient voiceServiceClient;

    public TtsController(VoiceServiceClient voiceServiceClient) {
        this.voiceServiceClient = voiceServiceClient;
    }

    @PostMapping("/speak")
    public ResponseEntity<byte[]> speak(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody SpeakPayload payload) {
        if (jwt == null) {
            return ResponseEntity.status(401).build();
        }
        // Prefer languageCode (2-letter), fallback to language (e.g. "en", "ro")
        String lang = (payload.languageCode() != null && !payload.languageCode().isBlank())
                ? payload.languageCode()
                : payload.language();
        var tts = voiceServiceClient.synthesizeInstant(payload.text(), lang);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, tts.mediaType())
                .header("X-Audio-Codec", tts.codec())
                .header("X-Audio-Sample-Rate", String.valueOf(tts.sampleRate()))
                .body(tts.audioBytes());
    }

    /** text: only the reply content (not correction/tips). language/languageCode: 2-letter code for voice. */
    public record SpeakPayload(String text, String language, String languageCode) {
        public SpeakPayload(String text, String language) {
            this(text, language, null);
        }
    }
}
