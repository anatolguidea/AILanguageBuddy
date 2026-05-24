package com.example.ailanguagebuddy.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;

/**
 * Sliding-window rate limiter for AI endpoints.
 * Limits each authenticated user to MAX_REQUESTS_PER_WINDOW requests per window.
 *
 * Note: in-memory only — resets on restart and does not scale across instances.
 * For multi-instance deployments, replace with Redis-backed rate limiting.
 */
@Component
public class RateLimitInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(RateLimitInterceptor.class);
    private static final int MAX_REQUESTS_PER_WINDOW = 30;
    private static final Duration WINDOW = Duration.ofMinutes(1);

    private final Map<String, Deque<Instant>> timestamps = new HashMap<>();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {
        if (!"/api/v1/chat/ask".equals(request.getRequestURI())) {
            return true;
        }

        String userId = extractUserId();
        if (userId == null) {
            return true;
        }

        Instant now = Instant.now();
        Instant windowStart = now.minus(WINDOW);

        synchronized (this) {
            Deque<Instant> times = timestamps.computeIfAbsent(userId, k -> new ArrayDeque<>());
            times.removeIf(t -> t.isBefore(windowStart));
            if (times.size() >= MAX_REQUESTS_PER_WINDOW) {
                log.warn("Rate limit exceeded: userId={} requests={}", userId, times.size());
                writeTooManyRequests(response);
                return false;
            }
            times.addLast(now);
        }

        return true;
    }

    private static String extractUserId() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwtAuth) {
            return jwtAuth.getToken().getSubject();
        }
        return null;
    }

    private static void writeTooManyRequests(HttpServletResponse response) throws IOException {
        response.setStatus(429);
        response.setContentType("application/json");
        response.getWriter().write(
                "{\"message\":\"Too many requests. Please wait before sending another message.\",\"code\":\"RATE_LIMITED\"}");
    }
}
