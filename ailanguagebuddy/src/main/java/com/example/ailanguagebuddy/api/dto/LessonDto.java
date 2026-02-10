package com.example.ailanguagebuddy.api.dto;

import java.util.Map;
import java.util.UUID;

public record LessonDto(
        UUID id,
        String title,
        String description,
        String status, // locked, available, completed
        Map<String, Object> content,
        int orderIndex) {
}
