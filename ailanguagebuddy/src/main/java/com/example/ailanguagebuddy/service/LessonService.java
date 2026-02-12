package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.api.dto.LessonDto;
import com.example.ailanguagebuddy.model.Lesson;
import com.example.ailanguagebuddy.model.UserLessonProgress;
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
        private final JdbcTemplate jdbcTemplate;

        public LessonService(
                        LessonRepository lessonRepository,
                        UserLessonProgressRepository progressRepository,
                        JdbcTemplate jdbcTemplate) {
                this.lessonRepository = lessonRepository;
                this.progressRepository = progressRepository;
                this.jdbcTemplate = jdbcTemplate;
        }

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
                                                        resolvedLanguage),
                                        lesson.getOrderIndex() != null ? lesson.getOrderIndex() : 0));
                }

                return results;
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
                        String targetLanguage) {
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

                // Otherwise generate dynamic content based on Lexemes
                List<Lexeme> lexemes = lexemesForLanguage(targetLanguage);
                if (lexemes.isEmpty())
                        return content;

                int seedIndex = Math.max(0, ((orderIndex == null ? 1 : orderIndex) - 1) % lexemes.size());

                // Select a focus word and some distractors
                Lexeme focus = lexemes.get(seedIndex);
                Lexeme distractorA = lexemes.get((seedIndex + 1) % lexemes.size());
                Lexeme distractorB = lexemes.get((seedIndex + 2) % lexemes.size());
                Lexeme distractorC = lexemes.get((seedIndex + 3) % lexemes.size());

                List<Map<String, Object>> challenges = new ArrayList<>();

                // 1. IMAGE_CHOICE (now Emoji based): 3 emojis with labels, one correct
                challenges.add(imageChoiceCard(focus, distractorA, distractorB));

                // 2. TRANSLATE_PICKER: A sentence with a word bank (Choice chip style)
                challenges.add(translatePickerCard(focus, distractorA, distractorB));

                // 3. SENTENCE_BUILDER: Reorder words to translate a phrase
                challenges.add(sentenceBuilderCard(focus, distractorA));

                content.put("source_language", "en");
                content.put("target_language", targetLanguage);
                content.put("challenges", challenges);
                return content;
        }

        /**
         * IMAGE_CHOICE: 3 options with Emojis, one correct.
         */
        private Map<String, Object> imageChoiceCard(Lexeme focus, Lexeme a, Lexeme b) {
                List<Map<String, Object>> options = new ArrayList<>();
                options.add(optionWithEmoji(focus.targetWord, true, focus.emoji));
                options.add(optionWithEmoji(a.targetWord, false, a.emoji));
                options.add(optionWithEmoji(b.targetWord, false, b.emoji));
                Collections.shuffle(options);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "IMAGE_CHOICE");
                card.put("question", "Which one is \"" + focus.englishWord + "\"?");
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
        private Map<String, Object> translatePickerCard(Lexeme focus, Lexeme a, Lexeme b) {
                List<String> options = new ArrayList<>();
                options.add(a.targetWord);
                options.add(focus.targetWord);
                options.add(b.targetWord);
                Collections.shuffle(options);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "TRANSLATE_PICKER");
                card.put("question", "How do you say \"" + focus.englishWord + "\"?");
                card.put("options", options);
                card.put("correct_answer", focus.targetWord);
                return card;
        }

        /**
         * SENTENCE_BUILDER: Reorder words to translate a phrase.
         */
        private Map<String, Object> sentenceBuilderCard(Lexeme focus, Lexeme distractor) {
                List<String> wordBank = new ArrayList<>(focus.correctOrder);
                // Add some distractors to the bank
                wordBank.add(distractor.targetWord.split(" ")[0]);
                Collections.shuffle(wordBank);

                Map<String, Object> card = new LinkedHashMap<>();
                card.put("type", "SENTENCE_BUILDER");
                card.put("question", "Translate this sentence");
                card.put("sentence_to_translate",
                                focus.englishPhrase != null ? focus.englishPhrase : focus.englishWord);
                card.put("word_bank", wordBank);
                card.put("correct_order", focus.correctOrder);
                return card;
        }

        private List<Lexeme> lexemesForLanguage(String languageCode) {
                String lang = languageCode == null ? "es" : languageCode.toLowerCase();

                // Expanded language support with basic vocabulary and Emojis
                return switch (lang) {
                        case "fr" -> List.of(
                                        new Lexeme("coffee", "I would like a coffee", "un café", "Je voudrais un café",
                                                        List.of("Je", "voudrais", "un", "café"), "☕"),
                                        new Lexeme("tea", "One tea please", "un thé", "Un thé s'il vous plaît",
                                                        List.of("Un", "thé", "s'il", "vous", "plaît"), "🍵"),
                                        new Lexeme("water", "Some water", "de l'eau", "De l'eau",
                                                        List.of("De", "l'eau"), "💧"),
                                        new Lexeme("bread", "I eat bread", "du pain", "Je mange du pain",
                                                        List.of("Je", "mange", "du", "pain"), "🍞"));
                        case "de" -> List.of(
                                        new Lexeme("coffee", "I drink coffee", "ein Kaffee", "Ich trinke Kaffee",
                                                        List.of("Ich", "trinke", "Kaffee"), "☕"),
                                        new Lexeme("tea", "A tea please", "ein Tee", "Einen Tee bitte",
                                                        List.of("Einen", "Tee", "bitte"), "🍵"),
                                        new Lexeme("water", "I need water", "Wasser", "Ich brauche Wasser",
                                                        List.of("Ich", "brauche", "Wasser"), "💧"),
                                        new Lexeme("bread", "The bread is good", "Brot", "Das Brot ist gut",
                                                        List.of("Das", "Brot", "ist", "gut"), "🍞"));
                        case "it" -> List.of(
                                        new Lexeme("coffee", "A coffee please", "un caffè", "Un caffè per favore",
                                                        List.of("Un", "caffè", "per", "favore"), "☕"),
                                        new Lexeme("tea", "I like tea", "un tè", "Mi piace il tè",
                                                        List.of("Mi", "piace", "il", "tè"), "🍵"),
                                        new Lexeme("pizza", "I want pizza", "una pizza", "Voglio una pizza",
                                                        List.of("Voglio", "una", "pizza"), "🍕"),
                                        new Lexeme("bread", "The bread is fresh", "il pane", "Il pane è fresco",
                                                        List.of("Il", "pane", "è", "fresco"), "🍞"));
                        case "pt" -> List.of(
                                        new Lexeme("coffee", "I drink coffee", "um café", "Eu bebo café",
                                                        List.of("Eu", "bebo", "café"), "☕"),
                                        new Lexeme("tea", "A tea please", "um chá", "Um chá por favor",
                                                        List.of("Um", "chá", "por", "favor"), "🍵"),
                                        new Lexeme("water", "I want water", "água", "Eu quero água",
                                                        List.of("Eu", "quero", "água"), "💧"),
                                        new Lexeme("bread", "Bread with butter", "pão", "Pão com manteiga",
                                                        List.of("Pão", "com", "manteiga"), "🍞"));
                        // Default to Spanish
                        default -> List.of(
                                        new Lexeme("coffee", "I want a coffee", "un café", "Yo quiero un café",
                                                        List.of("Yo", "quiero", "un", "café"), "☕"),
                                        new Lexeme("tea", "Review the tea", "un té", "Revisa el té",
                                                        List.of("Revisa", "el", "té"), "🍵"),
                                        new Lexeme("water", "I drink water", "agua", "Yo bebo agua",
                                                        List.of("Yo", "bebo", "agua"), "💧"),
                                        new Lexeme("bread", "The bread", "pan", "El pan", List.of("El", "pan"), "🍞"));
                };
        }

        private record Lexeme(
                        String englishWord,
                        String englishPhrase,
                        String targetWord,
                        String targetPhrase,
                        List<String> correctOrder,
                        String emoji) {
        }

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
