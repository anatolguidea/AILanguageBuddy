package com.example.ailanguagebuddy.api;

import java.time.Instant;

public record ApiError(
        String message,
        String code,
        Instant timestamp
) {
    public static ApiError of(String message, String code) {
        return new ApiError(message, code, Instant.now());
    }
}

