package com.example.ailanguagebuddy.service.voice.protocol;

public enum VoiceEventType {
    CONNECTED("connected"),
    PROCESSING("processing"),
    PARTIAL_TRANSCRIPT("partial_transcript"),
    TRANSCRIPT("transcript"),
    ASSISTANT_PARTIAL("assistant_partial"),
    ASSISTANT_TEXT("assistant_text"),
    AUDIO_END("audio_end"),
    JITTER_CONFIG("jitter_config"),
    ERROR("error"),
    START_TURN("start_turn"),
    END_TURN("end_turn");

    private final String wireValue;

    VoiceEventType(String wireValue) {
        this.wireValue = wireValue;
    }

    public String wireValue() {
        return wireValue;
    }

    public static VoiceEventType fromWireValue(String wireValue) {
        if (wireValue == null) {
            return null;
        }
        for (VoiceEventType type : values()) {
            if (type.wireValue.equals(wireValue)) {
                return type;
            }
        }
        return null;
    }
}
