package com.example.ailanguagebuddy.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

@Service
public class VoiceServiceClient {

    private final RestClient restClient;

    public VoiceServiceClient(RestClient.Builder builder) {
        this.restClient = builder.baseUrl("http://localhost:8000").build();
    }

    public String transcribe(byte[] audioData) {
        try {
            // Create a temporary resource for the byte array
            org.springframework.core.io.ByteArrayResource resource = new org.springframework.core.io.ByteArrayResource(
                    audioData) {
                @Override
                public String getFilename() {
                    return "audio.wav"; // Filename is often required by multipart handling
                }
            };

            // Build multipart body
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", resource);

            // Use Spring's RestClient to send multipart request
            // Note: Requires spring-web config for multipart converters, usually default in
            // Boot
            TranscriptionResponse response = restClient.post()
                    .uri("/transcribe")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(TranscriptionResponse.class);

            if (response != null && response.text() != null) {
                return response.text();
            }
        } catch (Exception e) {
            System.err.println("STT Error: " + e.getMessage());
            e.printStackTrace();
        }
        return "I could not understand that.";
    }

    // Record class to map the JSON response: {"text": "..."}
    public record TranscriptionResponse(String text) {
    }

    public byte[] synthesize(String text) {
        SpeakRequest request = new SpeakRequest(text, "en");
        return restClient.post()
                .uri("/synthesize/raw")
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(byte[].class);
    }

    public record SpeakRequest(String text, String language) {
    }
}
