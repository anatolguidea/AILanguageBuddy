package com.example.ailanguagebuddy.api.dto;

public record CorrectionDto(
        String original,
        String corrected,
        String explanation
) {}

