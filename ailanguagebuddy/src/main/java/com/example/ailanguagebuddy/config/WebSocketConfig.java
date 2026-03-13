package com.example.ailanguagebuddy.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final VoiceWebSocketHandler voiceWebSocketHandler;
    private final VoiceJwtHandshakeInterceptor voiceJwtHandshakeInterceptor;

    @Value("${app.websocket.allowed-origins:http://localhost,http://127.0.0.1}")
    private String websocketAllowedOrigins;

    public WebSocketConfig(
            VoiceWebSocketHandler voiceWebSocketHandler,
            VoiceJwtHandshakeInterceptor voiceJwtHandshakeInterceptor) {
        this.voiceWebSocketHandler = voiceWebSocketHandler;
        this.voiceJwtHandshakeInterceptor = voiceJwtHandshakeInterceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        String[] allowedOrigins = parseAllowedOrigins(websocketAllowedOrigins);
        registry.addHandler(voiceWebSocketHandler, "/ws/voice")
                .addInterceptors(voiceJwtHandshakeInterceptor)
                .setHandshakeHandler(new VoiceHandshakeHandler())
                .setAllowedOrigins(allowedOrigins);
    }

    private static String[] parseAllowedOrigins(String rawOrigins) {
        if (rawOrigins == null || rawOrigins.isBlank()) {
            throw new IllegalStateException("app.websocket.allowed-origins must be configured");
        }
        String trimmed = rawOrigins.trim();
        if ("*".equals(trimmed)) {
            throw new IllegalStateException("Wildcard origin is not allowed for websocket endpoints");
        }

        String[] origins = Arrays.stream(trimmed.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toArray(String[]::new);
        if (origins.length == 0) {
            throw new IllegalStateException("app.websocket.allowed-origins must include at least one origin");
        }
        return origins;
    }

    private static final class VoiceHandshakeHandler extends DefaultHandshakeHandler {
        @Override
        protected String selectProtocol(List<String> requestedProtocols, WebSocketHandler webSocketHandler) {
            if (requestedProtocols == null) {
                return null;
            }
            return requestedProtocols.stream()
                    .map(String::trim)
                    .filter(p -> "voice.v1".equalsIgnoreCase(p))
                    .findFirst()
                    .orElse(null);
        }
    }
}
