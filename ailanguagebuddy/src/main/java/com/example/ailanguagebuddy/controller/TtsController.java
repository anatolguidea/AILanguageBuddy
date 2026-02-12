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

        var tts = voiceServiceClient.synthesizeInstant(payload.text(), payload.language());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, tts.mediaType())
                .header("X-Audio-Codec", tts.codec())
                .header("X-Audio-Sample-Rate", String.valueOf(tts.sampleRate()))
                .body(tts.audioBytes());
    }

    public record SpeakPayload(String text, String language) {
    }
}
