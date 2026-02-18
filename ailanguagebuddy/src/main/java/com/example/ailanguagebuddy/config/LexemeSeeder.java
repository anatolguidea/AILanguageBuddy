package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.model.Lexeme;
import com.example.ailanguagebuddy.repository.LexemeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Seeds the lexemes table with Spanish vocabulary per theme (production content).
 * Runs only when no Spanish lexemes exist. Add more languages/themes by appending to the same table.
 */
@Component
@Order(1) // After SpanishLessonSeeder so lessons (and theme_key) exist
public class LexemeSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(LexemeSeeder.class);
    private static final String ES = "es";

    private final LexemeRepository lexemeRepository;

    public LexemeSeeder(LexemeRepository lexemeRepository) {
        this.lexemeRepository = lexemeRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (lexemeRepository.countByLanguageCode(ES) > 0) {
            return;
        }
        log.info("Seeding Spanish lexemes (production vocabulary in DB).");
        List<Lexeme> all = new ArrayList<>();
        all.addAll(spanishGreetings());
        all.addAll(spanishNumbersColors());
        all.addAll(spanishFamily());
        all.addAll(spanishFood());
        all.addAll(spanishRoutine());
        all.addAll(spanishTravel());
        all.addAll(spanishCommunication());
        all.addAll(spanishReview());
        lexemeRepository.saveAll(all);
        log.info("Seeded {} Spanish lexemes.", all.size());
    }

    private static Lexeme lex(String lang, String theme, String enWord, String enPhrase,
                              String targetWord, String targetPhrase, List<String> correctOrder, String emoji, int sort) {
        return Lexeme.builder()
                .languageCode(lang)
                .themeKey(theme)
                .englishWord(enWord)
                .englishPhrase(enPhrase)
                .targetWord(targetWord)
                .targetPhrase(targetPhrase)
                .correctOrder(correctOrder)
                .emoji(emoji)
                .sortOrder(sort)
                .build();
    }

    private List<Lexeme> spanishGreetings() {
        String t = "greetings";
        return List.of(
                lex(ES, t, "hello", "Hello, how are you?", "hola", "Hola, ¿cómo estás?", List.of("Hola", "¿cómo", "estás?"), "👋", 0),
                lex(ES, t, "goodbye", "See you later", "adiós", "Hasta luego", List.of("Hasta", "luego"), "👋", 1),
                lex(ES, t, "please", "One coffee please", "por favor", "Un café por favor", List.of("Un", "café", "por", "favor"), "🙏", 2),
                lex(ES, t, "thank you", "Thank you very much", "gracias", "Muchas gracias", List.of("Muchas", "gracias"), "🙏", 3)
        );
    }

    private List<Lexeme> spanishNumbersColors() {
        List<Lexeme> out = new ArrayList<>();
        String tNum = "numbers";
        out.add(lex(ES, tNum, "one", "One ticket", "uno", "Un billete", List.of("Un", "billete"), "1️⃣", 0));
        out.add(lex(ES, tNum, "two", "Two coffees", "dos", "Dos cafés", List.of("Dos", "cafés"), "2️⃣", 1));
        out.add(lex(ES, tNum, "three", "Three books", "tres", "Tres libros", List.of("Tres", "libros"), "3️⃣", 2));
        String tCol = "colors";
        out.add(lex(ES, tCol, "red", "The red car", "rojo", "El coche rojo", List.of("El", "coche", "rojo"), "🔴", 0));
        out.add(lex(ES, tCol, "blue", "The blue sky", "azul", "El cielo azul", List.of("El", "cielo", "azul"), "🔵", 1));
        out.add(lex(ES, tCol, "green", "The green tree", "verde", "El árbol verde", List.of("El", "árbol", "verde"), "🟢", 2));
        return out;
    }

    private List<Lexeme> spanishFamily() {
        String t = "family";
        return List.of(
                lex(ES, t, "mother", "My mother", "madre", "Mi madre", List.of("Mi", "madre"), "👩", 0),
                lex(ES, t, "father", "My father works", "padre", "Mi padre trabaja", List.of("Mi", "padre", "trabaja"), "👨", 1),
                lex(ES, t, "friend", "A good friend", "amigo", "Un buen amigo", List.of("Un", "buen", "amigo"), "👫", 2),
                lex(ES, t, "love", "I love Spanish", "amor", "Me encanta el español", List.of("Me", "encanta", "el", "español"), "❤️", 3)
        );
    }

    private List<Lexeme> spanishFood() {
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("food", "cafe", "restaurant")) {
            out.add(lex(ES, theme, "coffee", "I want a coffee", "un café", "Yo quiero un café", List.of("Yo", "quiero", "un", "café"), "☕", 0));
            out.add(lex(ES, theme, "tea", "I would like tea", "un té", "Quisiera un té", List.of("Quisiera", "un", "té"), "🍵", 1));
            out.add(lex(ES, theme, "water", "I drink water", "agua", "Yo bebo agua", List.of("Yo", "bebo", "agua"), "💧", 2));
            out.add(lex(ES, theme, "bread", "The bread is good", "pan", "El pan está bueno", List.of("El", "pan", "está", "bueno"), "🍞", 3));
            out.add(lex(ES, theme, "food", "The food is good", "comida", "La comida está buena", List.of("La", "comida", "está", "buena"), "🍽️", 4));
        }
        return out;
    }

    private List<Lexeme> spanishRoutine() {
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("days_weather", "shop", "routine", "body")) {
            out.add(lex(ES, theme, "today", "Today it rains", "hoy", "Hoy llueve", List.of("Hoy", "llueve"), "☀️", 0));
            out.add(lex(ES, theme, "tomorrow", "See you tomorrow", "mañana", "Hasta mañana", List.of("Hasta", "mañana"), "🌅", 1));
            out.add(lex(ES, theme, "time", "What time is it?", "hora", "¿Qué hora es?", List.of("¿Qué", "hora", "es?"), "🕐", 2));
            out.add(lex(ES, theme, "work", "I work a lot", "trabajo", "Trabajo mucho", List.of("Trabajo", "mucho"), "💼", 3));
            out.add(lex(ES, theme, "house", "My house is big", "casa", "Mi casa es grande", List.of("Mi", "casa", "es", "grande"), "🏠", 4));
        }
        return out;
    }

    private List<Lexeme> spanishTravel() {
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("transport", "hotel", "hobbies", "work", "interview", "doctor", "bank", "tech")) {
            out.add(lex(ES, theme, "train", "The train arrives", "tren", "El tren llega", List.of("El", "tren", "llega"), "🚂", 0));
            out.add(lex(ES, theme, "hotel", "A room in the hotel", "hotel", "Una habitación en el hotel",
                    List.of("Una", "habitación", "en", "el", "hotel"), "🏨", 1));
            out.add(lex(ES, theme, "doctor", "I need a doctor", "médico", "Necesito un médico", List.of("Necesito", "un", "médico"), "👨‍⚕️", 2));
            out.add(lex(ES, theme, "money", "I need money", "dinero", "Necesito dinero", List.of("Necesito", "dinero"), "💰", 3));
        }
        return out;
    }

    private List<Lexeme> spanishCommunication() {
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("opinions", "advice", "past", "future", "comparisons", "conditional", "kitchen", "culture", "news")) {
            out.add(lex(ES, theme, "problem", "No problem", "problema", "No hay problema", List.of("No", "hay", "problema"), "❓", 0));
            out.add(lex(ES, theme, "help", "I need help", "ayuda", "Necesito ayuda", List.of("Necesito", "ayuda"), "🆘", 1));
            out.add(lex(ES, theme, "book", "I read a book", "libro", "Leo un libro", List.of("Leo", "un", "libro"), "📖", 2));
            out.add(lex(ES, theme, "today", "Today it rains", "hoy", "Hoy llueve", List.of("Hoy", "llueve"), "☀️", 3));
        }
        return out;
    }

    private List<Lexeme> spanishReview() {
        String t = "review";
        return List.of(
                lex(ES, t, "hello", "Hello, how are you?", "hola", "Hola, ¿cómo estás?", List.of("Hola", "¿cómo", "estás?"), "👋", 0),
                lex(ES, t, "coffee", "I want a coffee", "un café", "Yo quiero un café", List.of("Yo", "quiero", "un", "café"), "☕", 1),
                lex(ES, t, "thank you", "Thank you very much", "gracias", "Muchas gracias", List.of("Muchas", "gracias"), "🙏", 2),
                lex(ES, t, "work", "I work a lot", "trabajo", "Trabajo mucho", List.of("Trabajo", "mucho"), "💼", 3)
        );
    }
}
