package com.example.ailanguagebuddy.api;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        String message,
        String code,
        Instant timestamp,
        Map<String, String> fieldErrors
) {
    public static ApiError of(String message, String code) {
        return new ApiError(message, code, Instant.now(), null);
    }

    public static ApiError validation(Map<String, String> fieldErrors) {
        String details = fieldErrors.entrySet().stream()
                .map(entry -> entry.getKey() + ": " + entry.getValue())
                .findFirst()
                .map(firstError -> "Validation failed: " + firstError)
                .orElse("Validation failed");
        return new ApiError(details, "VALIDATION_ERROR", Instant.now(), fieldErrors);
    }
}
