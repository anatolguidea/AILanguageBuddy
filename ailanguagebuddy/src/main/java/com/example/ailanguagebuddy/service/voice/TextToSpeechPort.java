package com.example.ailanguagebuddy.service.voice;

public interface TextToSpeechPort {
    byte[] synthesize(String text);
}
