package com.example.ailanguagebuddy.service.voice;

import org.springframework.stereotype.Service;

@Service
public class GeneratePartialTranscriptUseCase {

    private final PartialSpeechToTextPort partialSpeechToTextPort;

    public GeneratePartialTranscriptUseCase(PartialSpeechToTextPort partialSpeechToTextPort) {
        this.partialSpeechToTextPort = partialSpeechToTextPort;
    }

    public String execute(byte[] audioBytes) {
        if (audioBytes == null || audioBytes.length == 0) {
            return null;
        }
        try {
            String partial = partialSpeechToTextPort.transcribePartial(audioBytes);
            if (partial == null || partial.trim().isEmpty()) {
                return null;
            }
            return partial.trim();
        } catch (Exception ignored) {
            return null;
        }
    }
}
