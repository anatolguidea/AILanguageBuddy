package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.service.voice.SpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.PartialSpeechToTextPort;
import com.example.ailanguagebuddy.service.voice.TextToSpeechPort;
import com.example.ailanguagebuddy.service.voice.VoiceTurnException;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

@Service
public class VoiceServiceClient implements SpeechToTextPort, PartialSpeechToTextPort, TextToSpeechPort {

    private final RestClient restClient;

    public VoiceServiceClient(RestClient.Builder builder) {
        this.restClient = builder.baseUrl("http://localhost:8000").build();
    }

    public String transcribe(byte[] audioData) {
        try {
            TranscriptionResponse response = transcribeInternal(audioData, "/transcribe");

            if (response != null && response.text() != null) {
                return response.text();
            }
            throw new VoiceTurnException("stt_unavailable", "STT service returned an empty response");
        } catch (Exception e) {
            throw new VoiceTurnException("stt_unavailable", "Failed to transcribe audio", e);
        }
    }

    @Override
    public String transcribePartial(byte[] audioData) {
        try {
            TranscriptionResponse response = transcribeInternal(audioData, "/transcribe/partial");
            if (response != null && response.text() != null) {
                return response.text();
            }
            return "";
        } catch (Exception e) {
            return "";
        }
    }

    // Record class to map the JSON response: {"text": "..."}
    public record TranscriptionResponse(String text) {
    }

    private TranscriptionResponse transcribeInternal(byte[] audioData, String path) {
        org.springframework.core.io.ByteArrayResource resource = new org.springframework.core.io.ByteArrayResource(
                audioData) {
            @Override
            public String getFilename() {
                return "audio.wav";
            }
        };
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", resource);
        return restClient.post()
                .uri(path)
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(body)
                .retrieve()
                .body(TranscriptionResponse.class);
    }

    public byte[] synthesize(String text) {
        try {
            SpeakRequest request = new SpeakRequest(text, "en");
            byte[] audio = restClient.post()
                    .uri("/synthesize/raw")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(byte[].class);
            if (audio == null || audio.length == 0) {
                throw new VoiceTurnException("tts_failed", "TTS service returned empty audio");
            }
            return audio;
        } catch (Exception e) {
            throw new VoiceTurnException("tts_failed", "Failed to synthesize speech", e);
        }
    }

    public record SpeakRequest(String text, String language) {
    }
}
