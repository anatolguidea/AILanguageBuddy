package com.example.ailanguagebuddy.service;

public class VoiceServiceUnavailableException extends RuntimeException {
    public VoiceServiceUnavailableException(String message) {
        super(message);
    }

    public VoiceServiceUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
