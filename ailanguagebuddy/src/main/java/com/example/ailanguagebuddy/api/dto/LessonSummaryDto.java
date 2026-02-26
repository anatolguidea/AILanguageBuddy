package com.example.ailanguagebuddy.api.dto;

import java.util.UUID;

/**
 * Lightweight lesson metadata DTO used for fast "lesson list" loading.
 * Does NOT include content_json / interactive card payloads.
 */
public record LessonSummaryDto(
        UUID id,
        String title,
        String description,
        String status,
        int orderIndex
) {
}

