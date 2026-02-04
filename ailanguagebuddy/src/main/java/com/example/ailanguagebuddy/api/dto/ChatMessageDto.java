package com.example.ailanguagebuddy.api.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record ChatMessageDto(
        Long id,
        String content,
        String role,
        LocalDateTime createdAt,
        UUID userId
) {}

