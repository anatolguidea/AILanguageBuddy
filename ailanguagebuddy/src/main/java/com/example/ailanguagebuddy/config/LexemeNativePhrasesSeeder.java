package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.model.Lexeme;
import com.example.ailanguagebuddy.repository.LexemeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.Ordered;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * One-time style seeder that can populate native_phrases['ro'] for existing lexemes
 * from a CSV file maintained by content editors.
 *
 * CSV format (UTF-8), stored under src/main/resources/seed/native_phrases_ro.csv:
 *
 * english_key,ro_sentence
 * Hello, how are you?,Bună, ce mai faci?
 * The red car,Mașina roșie
 *
 * The english_key is matched against lexeme.englishPhrase; if englishPhrase is null,
 * we fall back to lexeme.englishWord.
 *
 * This class is intentionally conservative: it only updates rows that have a matching
 * english_key and does not overwrite an existing 'ro' entry in nativePhrases.
 */
@Component
public class LexemeNativePhrasesSeeder implements ApplicationRunner, Ordered {

    private static final Logger log = LoggerFactory.getLogger(LexemeNativePhrasesSeeder.class);

    private static final String RESOURCE_PATH = "seed/native_phrases_ro.csv";
    private static final String NATIVE_LOCALE = "ro";

    private final LexemeRepository lexemeRepository;

    public LexemeNativePhrasesSeeder(LexemeRepository lexemeRepository) {
        this.lexemeRepository = lexemeRepository;
    }

    @Override
    public int getOrder() {
        // Run after LexemeSeeder (which is @Order(1)), but before other generic runners.
        return 2;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            ClassPathResource resource = new ClassPathResource(RESOURCE_PATH);
            if (!resource.exists()) {
                log.info("No native phrases CSV found at {}. Skipping native_phrases seeding.", RESOURCE_PATH);
                return;
            }

            Map<String, String> roByEnglishKey = loadCsv(resource);
            if (roByEnglishKey.isEmpty()) {
                log.info("native_phrases CSV at {} is empty or only headers. Nothing to seed.", RESOURCE_PATH);
                return;
            }

            List<Lexeme> allLexemes = lexemeRepository.findAll();
            int updated = 0;

            for (Lexeme lexeme : allLexemes) {
                String englishKey = (lexeme.getEnglishPhrase() != null && !lexeme.getEnglishPhrase().isBlank())
                        ? lexeme.getEnglishPhrase().trim()
                        : lexeme.getEnglishWord() != null ? lexeme.getEnglishWord().trim() : null;

                if (englishKey == null || englishKey.isBlank()) {
                    continue;
                }

                String roSentence = roByEnglishKey.get(englishKey);
                if (roSentence == null || roSentence.isBlank()) {
                    continue;
                }

                Map<String, String> nativePhrases = lexeme.getNativePhrases();
                if (nativePhrases == null) {
                    nativePhrases = new HashMap<>();
                } else if (nativePhrases.containsKey(NATIVE_LOCALE)) {
                    // Don't overwrite existing curated content.
                    continue;
                }

                nativePhrases.put(NATIVE_LOCALE, roSentence);
                lexeme.setNativePhrases(nativePhrases);
                updated++;
            }

            if (updated > 0) {
                lexemeRepository.saveAll(allLexemes);
            }
            log.info("Seeded native_phrases['{}'] for {} lexemes based on {} CSV entries.",
                    NATIVE_LOCALE, updated, roByEnglishKey.size());
        } catch (Exception e) {
            log.error("Failed to seed lexeme native_phrases from {}.", RESOURCE_PATH, e);
        }
    }

    private Map<String, String> loadCsv(ClassPathResource resource) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {

            return reader.lines()
                    .skip(1) // header
                    .map(String::trim)
                    .filter(line -> !line.isEmpty() && !line.startsWith("#"))
                    .map(line -> {
                        // Simple CSV: english_key,ro_sentence (we allow commas in ro_sentence by splitting only on first comma)
                        int commaIndex = line.indexOf(',');
                        if (commaIndex <= 0) {
                            return null;
                        }
                        String englishKey = line.substring(0, commaIndex).trim();
                        String roSentence = line.substring(commaIndex + 1).trim();
                        if (englishKey.isEmpty() || roSentence.isEmpty()) {
                            return null;
                        }
                        return Map.entry(englishKey, roSentence);
                    })
                    .filter(e -> e != null)
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (a, b) -> b));
        } catch (Exception e) {
            log.error("Failed to read native phrases CSV at {}.", RESOURCE_PATH, e);
            return Map.of();
        }
    }
}

