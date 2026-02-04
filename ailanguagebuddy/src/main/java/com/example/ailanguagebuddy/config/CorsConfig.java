package com.example.ailanguagebuddy.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    /**
     * Comma-separated list of allowed origins, e.g.
     * - http://localhost:5173
     * - http://127.0.0.1:8080
     * - http://192.168.1.5:1234
     *
     * For dev you can set: CORS_ALLOWED_ORIGINS=*
     */
    @Value("${app.cors.allowed-origins:*}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        var mapping = registry.addMapping("/**")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false);

        if ("*".equals(allowedOrigins.trim())) {
            mapping.allowedOriginPatterns("*");
            return;
        }

        List<String> origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
        if (!origins.isEmpty()) {
            mapping.allowedOrigins(origins.toArray(String[]::new));
        }
    }
}

