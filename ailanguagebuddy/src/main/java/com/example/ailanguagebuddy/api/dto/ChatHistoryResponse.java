package com.example.ailanguagebuddy.api.dto;

import java.util.List;

public record ChatHistoryResponse(
        List<ChatMessageDto> items,
        String nextCursor
) {}

