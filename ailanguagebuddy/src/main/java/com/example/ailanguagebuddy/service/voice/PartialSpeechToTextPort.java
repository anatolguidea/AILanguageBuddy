package com.example.ailanguagebuddy.service.voice;

public interface PartialSpeechToTextPort {
    String transcribePartial(byte[] audioData);
}
