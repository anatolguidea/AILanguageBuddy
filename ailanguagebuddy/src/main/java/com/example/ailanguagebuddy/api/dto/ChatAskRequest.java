package com.example.ailanguagebuddy.api.dto;

/**
 * Request from the mobile client to the language coach.
 * Additional fields are optional for now but allow adaptive pedagogy.
 */
public record ChatAskRequest(
        String message,
        String targetLanguage,
        String nativeLanguage,
        String level,
        String mode
) {}

