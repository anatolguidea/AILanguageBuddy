package com.example.ailanguagebuddy.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {

    /**
     * Shared ObjectMapper used across the application.
     * Spring Boot can auto-configure this when using the full web starter,
     * but since this project uses the more minimal webmvc starter we declare it explicitly.
     */
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}

