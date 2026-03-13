package com.example.ailanguagebuddy.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.http.HttpMethod;
import org.springframework.web.client.RestTemplate;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .authorizeHttpRequests(auth -> auth
                        // allow preflight
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // allow basic health/info endpoints if you add them later
                        .requestMatchers("/actuator/health").permitAll()
                        // protect API
                        .requestMatchers("/api/v1/**").authenticated()
                        .anyRequest().permitAll())
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                .build();
    }

    /**
     * Custom JwtDecoder that validates Supabase access tokens using the JWKS
     * endpoint.
     * We keep validation intentionally minimal here (signature + expiry) to avoid
     * tight coupling to issuer/audience details and keep local dev simple.
     */
    @Bean
    JwtDecoder jwtDecoder() {
        String jwkSetUri = "https://ehpwqatgjqfwosoibmoz.supabase.co/auth/v1/.well-known/jwks.json";

        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(30_000);
        requestFactory.setReadTimeout(30_000);
        RestTemplate restTemplate = new RestTemplate(requestFactory);

        // Configure Nimbus to use JWKS but explicitly support ES256 (for Supabase ECC
        // keys)
        // We also keep RS256 for backward compatibility if needed.
        NimbusJwtDecoder delegate = NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
                .restOperations(restTemplate)
                .jwsAlgorithm(org.springframework.security.oauth2.jose.jws.SignatureAlgorithm.ES256)
                // .jwsAlgorithm(SignatureAlgorithm.RS256) // Optional: If we needed both, we'd
                // use a different builder
                .build();

        return token -> {
            try {
                return delegate.decode(token);
            } catch (Exception e) {
                System.out.println(">>> JWT DECODE ERROR (JWKS/ES256): " + e.getMessage());
                // e.printStackTrace();
                throw e;
            }
        };
    }
}
