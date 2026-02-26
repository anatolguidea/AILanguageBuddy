package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.api.dto.LessonDto;
import com.example.ailanguagebuddy.api.dto.LessonSummaryDto;
import com.example.ailanguagebuddy.model.Lesson;
import com.example.ailanguagebuddy.model.UserLessonProgress;
import com.example.ailanguagebuddy.repository.LexemeRepository;
import com.example.ailanguagebuddy.repository.LessonRepository;
import com.example.ailanguagebuddy.repository.UserLessonProgressRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class LessonService {

        private final LessonRepository lessonRepository;
        private final UserLessonProgressRepository progressRepository;
        private final LexemeRepository lexemeRepository;
        private final JdbcTemplate jdbcTemplate;

        // Keep in sync with lesson seeders (orderIndex 1..30).
        private static final String[] THEME_KEYS = {
                        "greetings", "numbers", "colors", "family", "food", "cafe", "days_weather", "shop", "routine",
                        "body", "restaurant", "transport", "hotel", "hobbies", "work", "interview", "doctor", "bank",
                        "tech", "opinions", "advice", "past", "future", "comparisons", "conditional", "kitchen", "culture",
                        "news", "review", "review"
        };

        public LessonService(
                        LessonRepository lessonRepository,
                        UserLessonProgressRepository progressRepository,
                        LexemeRepository lexemeRepository,
                        JdbcTemplate jdbcTemplate) {
                this.lessonRepository = lessonRepository;
                this.progressRepository = progressRepository;
                this.lexemeRepository = lexemeRepository;
                this.jdbcTemplate = jdbcTemplate;
        }

        @org.springframework.cache.annotation.Cacheable(cacheNames = "lessonDetails")
        public List<LessonDto> getLessonsForUser(UUID userId, String languageCode) {
                String resolvedLanguage = resolveTargetLanguage(userId, languageCode);

                // 1. Fetch all lessons for the language, sorted by order
                // Filters strictly by target_language to prevent "overlapping lessons"
                List<Lesson> lessons = lessonRepository.findByLanguageCode(resolvedLanguage, Sort.by("orderIndex"));

                // 2. Fetch user progress for this specific language context
                // We might want to filter progress by language too if the progress table stores
                // it,
                // but typically progress is linked to lesson_id, which is already
                // language-specific.
                List<UserLessonProgress> progressList = progressRepository.findByUserId(userId);
                Map<UUID, String> statusMap = progressList.stream()
                                .collect(Collectors.toMap(UserLessonProgress::getLessonId,
                                                UserLessonProgress::getStatus));

                List<LessonDto> results = new ArrayList<>();
                boolean previousCompleted = true; // First lesson is available by default

                for (Lesson lesson : lessons) {
                        String status = statusMap.getOrDefault(lesson.getId(), "locked");

                        // Logic: If status is explicitly 'completed' or 'started', keep it.
                        // If it's 'locked' (default), check if previous was completed.
                        if (status.equals("locked")) {
                                if (previousCompleted) {
                                        status = "available";
                                }
                        }

                        // Update previousCompleted for next iteration
                        previousCompleted = "completed".equalsIgnoreCase(status);

                        results.add(new LessonDto(
                                        lesson.getId(),
                                        lesson.getTitle(),
                                        lesson.getDescription(),
                                        status,
                                        enrichWithInteractiveCards(lesson.getContentJson(), lesson.getOrderIndex(),
                                                        resolvedLanguage, lesson.getThemeKey()),
                                        lesson.getOrderIndex() != null ? lesson.getOrderIndex() : 0));
                }

                return results;
        }

        /**
         * Lightweight metadata view used by the mobile app to render the lesson list quickly.
         * DOES NOT generate interactive card content.
         */
        @org.springframework.cache.annotation.Cacheable(cacheNames = "lessonSummaries")
        public List<LessonSummaryDto> getLessonSummariesForUser(UUID userId, String languageCode) {
                // Cache summaries per user+language pair.
                // The key is derived automatically from method parameters.
                // These are effectively static for seeded lessons.
                String resolvedLanguage = resolveTargetLanguage(userId, languageCode);

                List<Lesson> lessons = lessonRepository.findByLanguageCode(resolvedLanguage, Sort.by("orderIndex"));
                List<UserLessonProgress> progressList = progressRepository.findByUserId(userId);
                Map<UUID, String> statusMap = progressList.stream()
                                .collect(Collectors.toMap(UserLessonProgress::getLessonId,
                                                UserLessonProgress::getStatus));

                List<LessonSummaryDto> results = new ArrayList<>();
                boolean previousCompleted = true;

                for (Lesson lesson : lessons) {
                        String status = statusMap.getOrDefault(lesson.getId(), "locked");

                        if (status.equals("locked")) {
                                if (previousCompleted) {
                                        status = "available";
                                }
                        }

                        previousCompleted = "completed".equalsIgnoreCase(status);

                        results.add(new LessonSummaryDto(
                                        lesson.getId(),
                                        lesson.getTitle(),
                                        lesson.getDescription(),
                                        status,
                                        lesson.getOrderIndex() != null ? lesson.getOrderIndex() : 0));
                }

                return results;
        }

        /**
         * Fetch a single lesson with its interactive content for the detail screen.
         * Reuses the existing getLessonsForUser logic to preserve gating and status rules.
         */
        public LessonDto getLessonForUser(UUID userId, UUID lessonId, String languageCode) {
                return getLessonsForUser(userId, languageCode).stream()
                                .filter(dto -> dto.id().equals(lessonId))
                                .findFirst()
                                .orElseThrow(() -> new IllegalArgumentException("Lesson not found: " + lessonId));
        }

        private String resolveTargetLanguage(UUID userId, String requestedLanguage) {
                if (requestedLanguage != null && !requestedLanguage.isBlank()) {
                        return requestedLanguage.toLowerCase();
                }
                try {
                        String sql = """
                                        SELECT COALESCE(
                                            (SELECT LOWER(target_language) FROM public.profiles WHERE id = ? LIMIT 1),
                                            (SELECT LOWER(raw_user_meta_data ->> 'target_language') FROM auth.users WHERE id = ? LIMIT 1),
                                            'es'
                                        )
                                        """;
                        String result = jdbcTemplate.queryForObject(sql, String.class, userId, userId);
                        return (result == null || result.isBlank()) ? "es" : result;
                } catch (Exception ignored) {
                        return "es";
                }
        }

        private Map<String, Object> enrichWithInteractiveCards(Map<String, Object> original, Integer orderIndex,
                        String targetLanguage, String themeKey) {
                Map<String, Object> content = new LinkedHashMap<>();
                if (original != null) {
                        content.putAll(original);
                }
                // If challenges are already present in DB JSON, use them.
                if (content.containsKey("challenges") && content.get("challenges") instanceof List
                                && !((List<?>) content.get("challenges")).isEmpty()) {
                        content.put("target_language", targetLanguage);
                        return content;
                }

                // Production: load lexemes from DB by (language, theme).
                String resolvedTheme = themeKey;
                if (resolvedTheme == null || resolvedTheme.isBlank()) {
                        int idx = (orderIndex == null ? 1 : orderIndex) - 1;
                        if (idx >= 0 && idx < THEME_KEYS.length) {
                                resolvedTheme = THEME_KEYS[idx];
                        }
                }

                List<LexemeData> lexemes = (resolvedTheme == null || resolvedTheme.isBlank())
                                ? List.of()
                                : lexemesFromDb(targetLanguage, resolvedTheme);

                // If theme has no lexemes, fall back to review theme (still DB-backed).
                if (lexemes.isEmpty() && !"review".equalsIgnoreCase(resolvedTheme)) {
                        lexemes = lexemesFromDb(targetLanguage, "review");
                }
                if (lexemes.isEmpty())
                        return content;

                int seedIndex = Math.max(0, ((orderIndex == null ? 1 : orderIndex) - 1) % lexemes.size());

                LexemeData focus = lexemes.get(seedIndex);
                LexemeData distractorA = lexemes.get((seedIndex + 1) % lexemes.size());
                LexemeData distractorB = lexemes.get((seedIndex + 2) % lexemes.size());

                List<Map<String, Object>> challenges = new ArrayList<>();
                challenges.add(imageChoiceCard(focus, distractorA, distractorB));
                challenges.add(translatePickerCard(focus, distractorA, distractorB));
                challenges.add(sentenceBuilderCard(focus, distractorA, targetLanguage));

                content.put("source_language", "en");
                content.put("target_language", targetLanguage);
                content.put("challenges", challenges);
                return content;
        }

        /** Load lexemes from DB for (language, theme). Returns empty list if none. */
        private List<LexemeData> lexemesFromDb(String languageCode, String themeKey) {
                List<com.example.ailanguagebuddy.model.Lexeme> entities = lexemeRepository
                                .findByLanguageCodeAndThemeKeyOrderBySortOrderAsc(languageCode, themeKey);
                return entities.stream()
                                .map(e -> new LexemeData(
                                                e.getEnglishWord(),
                                                e.getEnglishPhrase(),
                                                e.getTargetWord(),
                                                e.getTargetPhrase(),
                                                e.getCorrectOrder() != null ? e.getCorrectOrder() : List.of(),
                                                e.getEmoji(),
                                                e.getNativePhrases(),
                                                e.getNativePrompts()))
                                .toList();
        }

        /**
         * IMAGE_CHOICE: 3 options with Emojis, one correct.
         */
        private Map<String, Object> imageChoiceCard(LexemeData focus, LexemeData a, LexemeData b) {
                List<Map<String, Object>> options = new ArrayList<>();
                options.add(optionWithEmoji(focus.targetWord, true, focus.emoji));
                options.add(optionWithEmoji(a.targetWord, false, a.emoji));
                options.add(optionWithEmoji(b.targetWord, false, b.emoji));
                Collections.shuffle(options);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "IMAGE_CHOICE");

                // Backward-compatible question text (still English for now).
                card.put("question", "Which one is \"" + focus.englishWord + "\"?");

                // New structured instruction map (per native/app language).
                Map<String, String> instruction = new LinkedHashMap<>();
                instruction.put("en", "Select the correct translation.");
                card.put("instruction", instruction);

                // Optional prompt payload describing what is being asked about, per source language.
                Map<String, String> prompt = new LinkedHashMap<>();
                if (focus.nativePrompts != null) {
                        prompt.putAll(focus.nativePrompts);
                }
                // Always ensure we have at least an English fallback referencing the base word.
                prompt.putIfAbsent("en", "Which word means \"" + focus.englishWord + "\"?");
                card.put("prompt_native", prompt);

                card.put("options", options);
                return card;
        }

        private Map<String, Object> optionWithEmoji(String text, boolean correct, String emoji) {
                Map<String, Object> option = new LinkedHashMap<>();
                option.put("text", text);
                option.put("correct", correct);
                option.put("emoji", emoji);
                return option;
        }

        /**
         * TRANSLATE_PICKER: A sentence with a word bank (Multiple choice / Chips).
         */
        private Map<String, Object> translatePickerCard(LexemeData focus, LexemeData a, LexemeData b) {
                List<String> options = new ArrayList<>();
                options.add(a.targetWord);
                options.add(focus.targetWord);
                options.add(b.targetWord);
                Collections.shuffle(options);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "TRANSLATE_PICKER");

                // Backward-compatible question text (still English for now).
                card.put("question", "How do you say \"" + focus.englishWord + "\"?");

                // New structured instruction map (per native/app language).
                Map<String, String> instruction = new LinkedHashMap<>();
                instruction.put("en", "Select the correct translation.");
                card.put("instruction", instruction);

                // Optional prompt payload describing what is being translated, per source language.
                Map<String, String> prompt = new LinkedHashMap<>();
                if (focus.nativePrompts != null) {
                        prompt.putAll(focus.nativePrompts);
                }
                // Always ensure we have at least an English fallback referencing the base word.
                prompt.putIfAbsent("en", "How do you say \"" + focus.englishWord + "\"?");
                card.put("prompt_native", prompt);

                card.put("options", options);
                card.put("correct_answer", focus.targetWord);
                return card;
        }

        /**
         * SENTENCE_BUILDER: Reorder words to translate a phrase.
         */
        private Map<String, Object> sentenceBuilderCard(LexemeData focus, LexemeData distractor, String targetLanguage) {
                List<String> wordBank = new ArrayList<>(focus.correctOrder);
                // Add some distractors to the bank
                wordBank.add(distractor.targetWord.split(" ")[0]);
                Collections.shuffle(wordBank);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "SENTENCE_BUILDER");

                // Structured instruction, keyed by native/app language (English-only for now).
                Map<String, String> instruction = new LinkedHashMap<>();
                instruction.put("en", "Translate this sentence.");
                card.put("instruction", instruction);

                // Base English sentence we are translating from.
                String englishSentence = focus.englishPhrase != null ? focus.englishPhrase : focus.englishWord;

                // Backward-compatible fields used by existing clients.
                card.put("question", "Translate this sentence");
                card.put("sentence_to_translate", englishSentence);

                // New structured sentence maps:
                // - sentence_native: same sentence expressed in the learner's native/app language(s).
                Map<String, String> sentenceNative = new LinkedHashMap<>();
                if (focus.nativePhrases != null) {
                        sentenceNative.putAll(focus.nativePhrases);
                }
                // Always ensure we have at least the English base as a fallback.
                sentenceNative.putIfAbsent("en", englishSentence);
                card.put("sentence_native", sentenceNative);

                // - sentence_target: sentence expressed in the target learning language.
                Map<String, String> sentenceTarget = new LinkedHashMap<>();
                String targetSentence = focus.targetPhrase != null && !focus.targetPhrase.isBlank()
                                ? focus.targetPhrase
                                : String.join(" ", focus.correctOrder);
                sentenceTarget.put(targetLanguage, targetSentence);
                card.put("sentence_target", sentenceTarget);

                card.put("word_bank", wordBank);
                card.put("correct_order", focus.correctOrder);
                return card;
        }

        private record LexemeData(
                        String englishWord,
                        String englishPhrase,
                        String targetWord,
                        String targetPhrase,
                        List<String> correctOrder,
                        String emoji,
                        Map<String, String> nativePhrases,
                        Map<String, String> nativePrompts) {
        }

        @org.springframework.cache.annotation.CacheEvict(cacheNames = {
                        "lessonSummaries",
                        "lessonDetails"
        }, allEntries = true)
        public void completeLesson(UUID userId, UUID lessonId) {
                UserLessonProgress progress = progressRepository
                                .findById(new com.example.ailanguagebuddy.model.UserLessonProgressId(userId, lessonId))
                                .orElse(com.example.ailanguagebuddy.model.UserLessonProgress.builder()
                                                .userId(userId)
                                                .lessonId(lessonId)
                                                .status("started")
                                                .build());

                progress.setStatus("completed");
                progress.setCompletedAt(java.time.LocalDateTime.now());
                progress.setUpdatedAt(java.time.LocalDateTime.now());

                progressRepository.save(progress);
        }
}
