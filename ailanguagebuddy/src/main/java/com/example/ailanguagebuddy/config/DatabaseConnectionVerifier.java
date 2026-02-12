package com.example.ailanguagebuddy.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.net.URI;

@Configuration
public class DatabaseConnectionVerifier {
    private static final Logger log = LoggerFactory.getLogger(DatabaseConnectionVerifier.class);

    @Bean
    ApplicationRunner verifyDatabaseConnection(
            DataSource dataSource,
            JdbcTemplate jdbcTemplate,
            @Value("${spring.datasource.url:}") String datasourceUrl) {
        return args -> {
            if (datasourceUrl == null || datasourceUrl.isBlank()) {
                log.error("spring.datasource.url is empty. Set DATASOURCE_URL to your Supabase Postgres URI.");
                return;
            }
            log.info("Datasource URL host: {}", extractHostSafely(datasourceUrl));
            try {
                String currentDb = jdbcTemplate.queryForObject("select current_database()", String.class);
                log.info("Connected database: {}", currentDb);
            } catch (Exception ex) {
                log.error("DB verification query failed: {}", ex.getMessage());
            }
        };
    }

    private String extractHostSafely(String jdbcUrl) {
        try {
            String stripped = jdbcUrl.replace("jdbc:", "");
            URI uri = URI.create(stripped);
            return uri.getHost() == null ? "(unknown host)" : uri.getHost();
        } catch (Exception ignored) {
            return "(invalid datasource url)";
        }
    }
}
