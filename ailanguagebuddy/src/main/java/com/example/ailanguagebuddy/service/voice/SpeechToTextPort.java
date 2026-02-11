package com.example.ailanguagebuddy.service.voice;

public interface SpeechToTextPort {
    String transcribe(byte[] audioData);
}
