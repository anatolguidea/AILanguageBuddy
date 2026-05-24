package com.example.ailanguagebuddy.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request from the mobile client to the language coach.
 * instructionLocale: when "ro", the AI provides correction/tips text in Romanian.
 */
public record ChatAskRequest(
        @NotBlank(message = "Message must not be blank")
        @Size(max = 2000, message = "Message must not exceed 2000 characters")
        String message,

        @Size(max = 100, message = "Target language must not exceed 100 characters")
        String targetLanguage,

        @Size(max = 100, message = "Native language must not exceed 100 characters")
        String nativeLanguage,

        @Size(max = 32, message = "Level must not exceed 32 characters")
        String level,

        @Size(max = 100, message = "Mode must not exceed 100 characters")
        String mode,

        @Size(max = 10, message = "Instruction locale must not exceed 10 characters")
        String instructionLocale
) {}
