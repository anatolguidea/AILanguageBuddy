package com.example.ailanguagebuddy.api.dto;

import java.util.List;

public record ChatAskResponse(
        String replyText,
        String correction,
        String tips,
        List<CorrectionDto> corrections,
        List<VocabularyItemDto> vocabulary
) {
    public ChatAskResponse(String replyText, String correction, String tips) {
        this(replyText, correction, tips, List.of(), List.of());
    }
}


