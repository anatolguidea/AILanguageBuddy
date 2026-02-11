package com.example.ailanguagebuddy.service.voice;

public class VoiceTurnException extends RuntimeException {
    private final String code;

    public VoiceTurnException(String code, String message) {
        super(message);
        this.code = code;
    }

    public VoiceTurnException(String code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public String code() {
        return code;
    }
}
