package com.example.ailanguagebuddy.domain;

/**
 * One concrete correction with context and explanation.
 */
public record Correction(
        String original,
        String corrected,
        String explanation
) {}

