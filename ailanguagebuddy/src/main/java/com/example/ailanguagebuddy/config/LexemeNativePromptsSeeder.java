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
 * Populates lexeme.nativePrompts['ro'] with fully native-language questions
 * (e.g. "Care cuvânt înseamnă «cafea»?") based on a CSV maintained by content editors.
 *
 * CSV format (UTF-8), stored under src/main/resources/seed/native_prompts_ro.csv:
 *
 * english_key,ro_prompt
 * coffee,Care cuvânt înseamnă „cafea”?
 *
 * english_key is matched against lexeme.englishWord; in ambiguous cases you can
 * choose to use the full englishPhrase instead and the seeder will prefer that.
 */
@Component
public class LexemeNativePromptsSeeder implements ApplicationRunner, Ordered {

    private static final Logger log = LoggerFactory.getLogger(LexemeNativePromptsSeeder.class);

    private static final String RESOURCE_PATH = "seed/native_prompts_ro.csv";
    private static final String NATIVE_LOCALE = "ro";

    private final LexemeRepository lexemeRepository;

    public LexemeNativePromptsSeeder(LexemeRepository lexemeRepository) {
        this.lexemeRepository = lexemeRepository;
    }

    @Override
    public int getOrder() {
        // Run after LexemeSeeder (1) and after native_phrases (2), but still early.
        return 3;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            ClassPathResource resource = new ClassPathResource(RESOURCE_PATH);
            if (!resource.exists()) {
                log.info("No native prompts CSV found at {}. Skipping native_prompts seeding.", RESOURCE_PATH);
                return;
            }

            Map<String, String> roByEnglishKey = loadCsv(resource);
            if (roByEnglishKey.isEmpty()) {
                log.info("native_prompts CSV at {} is empty or only headers. Nothing to seed.", RESOURCE_PATH);
                return;
            }

            List<Lexeme> allLexemes = lexemeRepository.findAll();
            int updated = 0;

            for (Lexeme lexeme : allLexemes) {
                String englishKey = (lexeme.getEnglishWord() != null && !lexeme.getEnglishWord().isBlank())
                        ? lexeme.getEnglishWord().trim()
                        : lexeme.getEnglishPhrase() != null ? lexeme.getEnglishPhrase().trim() : null;

                if (englishKey == null || englishKey.isBlank()) {
                    continue;
                }

                String roPrompt = roByEnglishKey.get(englishKey);
                if (roPrompt == null || roPrompt.isBlank()) {
                    continue;
                }

                Map<String, String> nativePrompts = lexeme.getNativePrompts();
                if (nativePrompts == null) {
                    nativePrompts = new HashMap<>();
                } else if (nativePrompts.containsKey(NATIVE_LOCALE)) {
                    // Don't overwrite existing curated content.
                    continue;
                }

                nativePrompts.put(NATIVE_LOCALE, roPrompt);
                lexeme.setNativePrompts(nativePrompts);
                updated++;
            }

            if (updated > 0) {
                lexemeRepository.saveAll(allLexemes);
            }
            log.info("Seeded native_prompts['{}'] for {} lexemes based on {} CSV entries.",
                    NATIVE_LOCALE, updated, roByEnglishKey.size());
        } catch (Exception e) {
            log.error("Failed to seed lexeme native_prompts from {}.", RESOURCE_PATH, e);
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
                        // english_key,ro_prompt  (ro_prompt can contain commas)
                        int commaIndex = line.indexOf(',');
                        if (commaIndex <= 0) {
                            return null;
                        }
                        String englishKey = line.substring(0, commaIndex).trim();
                        String roPrompt = line.substring(commaIndex + 1).trim();
                        if (englishKey.isEmpty() || roPrompt.isEmpty()) {
                            return null;
                        }
                        return Map.entry(englishKey, roPrompt);
                    })
                    .filter(e -> e != null)
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (a, b) -> b));
        } catch (Exception e) {
            log.error("Failed to read native prompts CSV at {}.", RESOURCE_PATH, e);
            return Map.of();
        }
    }
}

