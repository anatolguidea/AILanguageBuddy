package com.example.ailanguagebuddy.service.voice.protocol;

import java.util.Map;

public record VoiceEventMessage(Integer v, String event, String message, String code, Map<String, Object> data) {
}
