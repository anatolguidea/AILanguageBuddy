package com.example.ailanguagebuddy.api.dto;

/**
 * Request from the mobile client to the language coach.
 * instructionLocale: when "ro", the AI should provide correction/tips text in Romanian.
 */
public record ChatAskRequest(
        String message,
        String targetLanguage,
        String nativeLanguage,
        String level,
        String mode,
        String instructionLocale
) {}

