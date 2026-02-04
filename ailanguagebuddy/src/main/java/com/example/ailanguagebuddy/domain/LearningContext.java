package com.example.ailanguagebuddy.domain;

/**
 * Captures the learner's profile and current mode so prompts can be adapted.
 */
public record LearningContext(
        String targetLanguage,   // e.g. "English"
        String nativeLanguage,   // e.g. "Romanian"
        String level,            // e.g. "A2", "B1", "C1"
        String mode              // e.g. "chat", "scenario", "story"
) {
    public static LearningContext defaultChat() {
        return new LearningContext("English", "Romanian", "B1", "chat");
    }
}

