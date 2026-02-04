package com.example.ailanguagebuddy.security;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class AuthUserResolver {

    /**
     * Supabase access tokens put the user id into the standard JWT "sub" claim.
     */
    public AuthUser fromJwt(Jwt jwt) {
        String sub = jwt.getSubject();
        if (sub == null || sub.isBlank()) {
            throw new IllegalArgumentException("JWT subject (sub) is missing");
        }
        try {
            return new AuthUser(UUID.fromString(sub));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("JWT subject (sub) is not a UUID");
        }
    }
}
