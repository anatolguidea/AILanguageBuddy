package com.example.ailanguagebuddy.service.voice;

import java.util.UUID;

public interface TutorModelPort {
    String generateReply(String userText, UUID userId);
}
