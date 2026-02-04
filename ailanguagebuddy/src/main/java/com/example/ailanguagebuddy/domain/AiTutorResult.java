package com.example.ailanguagebuddy.domain;

import java.util.List;

/**
 * Structured result returned by the AI tutor for a single turn.
 */
public record AiTutorResult(
        String replyText,
        List<Correction> corrections,
        List<VocabularyItem> vocabulary
) {}

