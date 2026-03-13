package com.example.ailanguagebuddy.config;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Component
public class VoiceJwtHandshakeInterceptor implements HandshakeInterceptor {

    public static final String ATTR_AUTHENTICATED_USER_ID = "authenticatedUserId";
    private static final String AUTH_PROTOCOL_PREFIX = "bearer.";
    private static final String SEC_WEBSOCKET_PROTOCOL = "Sec-WebSocket-Protocol";

    private final JwtDecoder jwtDecoder;

    public VoiceJwtHandshakeInterceptor(JwtDecoder jwtDecoder) {
        this.jwtDecoder = jwtDecoder;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request,
                                   ServerHttpResponse response,
                                   WebSocketHandler wsHandler,
                                   java.util.Map<String, Object> attributes) {
        String token = extractTokenFromSubprotocols(request.getHeaders());
        if (token == null || token.isBlank()) {
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }

        try {
            Jwt jwt = jwtDecoder.decode(token);
            String sub = jwt.getSubject();
            if (sub == null || sub.isBlank()) {
                response.setStatusCode(HttpStatus.UNAUTHORIZED);
                return false;
            }
            UUID userId = UUID.fromString(sub);
            attributes.put(ATTR_AUTHENTICATED_USER_ID, userId);
            return true;
        } catch (Exception ex) {
            response.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request,
                               ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
        // no-op
    }

    private static String extractTokenFromSubprotocols(HttpHeaders headers) {
        String authHeader = headers.getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.regionMatches(true, 0, "Bearer ", 0, 7)) {
            String token = authHeader.substring(7).trim();
            if (!token.isEmpty()) {
                return token;
            }
        }

        List<String> rawHeaderValues = headers.getOrEmpty(SEC_WEBSOCKET_PROTOCOL);
        if (rawHeaderValues.isEmpty()) {
            return null;
        }

        List<String> protocols = new ArrayList<>();
        for (String rawValue : rawHeaderValues) {
            if (rawValue == null || rawValue.isBlank()) {
                continue;
            }
            for (String candidate : rawValue.split(",")) {
                String trimmed = candidate.trim();
                if (!trimmed.isEmpty()) {
                    protocols.add(trimmed);
                }
            }
        }

        for (String protocol : protocols) {
            if (protocol.regionMatches(true, 0, AUTH_PROTOCOL_PREFIX, 0, AUTH_PROTOCOL_PREFIX.length())) {
                String token = protocol.substring(AUTH_PROTOCOL_PREFIX.length()).trim();
                if (!token.isEmpty()) {
                    return token;
                }
            }
        }
        return null;
    }
}
