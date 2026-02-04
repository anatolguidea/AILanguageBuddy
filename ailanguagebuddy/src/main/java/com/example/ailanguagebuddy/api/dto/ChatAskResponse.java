package com.example.ailanguagebuddy.api.dto;

import java.util.List;

public record ChatAskResponse(
        String replyText,
        List<CorrectionDto> corrections,
        List<VocabularyItemDto> vocabulary
) {}


