package com.example.ailanguagebuddy.domain;

import java.util.List;

/**
 * Structured result returned by the AI tutor for a single turn.
 * LLM returns JSON: { "reply", "correction", "tips" }.
 */
public record AiTutorResult(
        String replyText,
        String translation,
        String correction,
        String tips,
        List<Correction> corrections,
        List<VocabularyItem> vocabulary
) {
    public AiTutorResult(String replyText, String translation, String correction, String tips) {
        this(replyText, translation, correction, tips, List.of(), List.of());
    }

    public AiTutorResult(String replyText, List<Correction> corrections, List<VocabularyItem> vocabulary) {
        this(replyText, null, null, null, corrections, vocabulary);
    }
}
