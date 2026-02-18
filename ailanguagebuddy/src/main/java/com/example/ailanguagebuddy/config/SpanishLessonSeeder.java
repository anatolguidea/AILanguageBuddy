package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.model.Lesson;
import com.example.ailanguagebuddy.repository.LessonRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Ensures we have a rich set of Spanish lessons (language_code = 'es').
 * Uses the same logic as existing lessons: contentJson left null so LessonService
 * generates interactive challenges dynamically from lexemes.
 */
@Component
@org.springframework.core.annotation.Order(0)
public class SpanishLessonSeeder implements ApplicationRunner {

    /** Used by LexemeSeeder to run after lessons are in place. */
    public static final int ORDER = 0;

    private static final Logger log = LoggerFactory.getLogger(SpanishLessonSeeder.class);
    private static final String LANGUAGE_CODE = "es";
    private static final int TARGET_COUNT = 30;

    private final LessonRepository lessonRepository;

    public SpanishLessonSeeder(LessonRepository lessonRepository) {
        this.lessonRepository = lessonRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        long existing = lessonRepository.countByLanguageCode(LANGUAGE_CODE);
        List<Lesson> allSpanish = lessonRepository.findByLanguageCode(LANGUAGE_CODE, org.springframework.data.domain.Sort.by("orderIndex"));
        boolean needThemeBackfill = allSpanish.stream().anyMatch(l -> l.getThemeKey() == null || l.getThemeKey().isBlank());

        if (existing != TARGET_COUNT) {
            if (existing > 0) {
                log.info("Replacing {} existing Spanish lessons with canonical {} themed lessons.", existing, TARGET_COUNT);
                lessonRepository.deleteByLanguageCode(LANGUAGE_CODE);
            } else {
                log.info("Seeding default Spanish lessons (none exist yet).");
            }
            saveCanonicalLessons();
        } else if (needThemeBackfill) {
            log.info("Backfilling theme_key on {} Spanish lessons.", allSpanish.size());
            for (int i = 0; i < allSpanish.size() && i < THEME_KEYS.length; i++) {
                Lesson lesson = allSpanish.get(i);
                lesson.setThemeKey(THEME_KEYS[i]);
            }
            lessonRepository.saveAll(allSpanish);
        }
    }

    private void saveCanonicalLessons() {
        List<LessonDefinition> definitions = spanishDefinitions();
        List<Lesson> toSave = new ArrayList<>();
        for (int i = 0; i < definitions.size(); i++) {
            LessonDefinition def = definitions.get(i);
            int orderIndex = i + 1;
            String themeKey = i < THEME_KEYS.length ? THEME_KEYS[i] : "review";
            Lesson lesson = Lesson.builder()
                    .languageCode(LANGUAGE_CODE)
                    .title(def.title())
                    .description(def.description())
                    .contentJson(new java.util.LinkedHashMap<>())
                    .orderIndex(orderIndex)
                    .themeKey(themeKey)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
            toSave.add(lesson);
        }
        lessonRepository.saveAll(toSave);
        log.info("Seeded {} Spanish lessons (language_code = {}).", toSave.size(), LANGUAGE_CODE);
    }

    /** Theme keys for production: lesson challenges load lexemes from DB by (language_code, theme_key). */
    private static final String[] THEME_KEYS = {
            "greetings", "numbers", "colors", "family", "food", "cafe", "days_weather", "shop", "routine",
            "body", "restaurant", "transport", "hotel", "hobbies", "work", "interview", "doctor", "bank",
            "tech", "opinions", "advice", "past", "future", "comparisons", "conditional", "kitchen", "culture",
            "news", "review", "review"
    };

    private List<LessonDefinition> spanishDefinitions() {
        List<LessonDefinition> list = new ArrayList<>();
        list.add(new LessonDefinition("Saludos y presentaciones", "Aprende a saludar y presentarte en español"));
        list.add(new LessonDefinition("Números del 1 al 10", "Cuenta y usa los números básicos"));
        list.add(new LessonDefinition("Colores básicos", "Nombra los colores en español"));
        list.add(new LessonDefinition("La familia", "Vocabulario de los miembros de la familia"));
        list.add(new LessonDefinition("Comida y bebida", "Palabras para comer y beber"));
        list.add(new LessonDefinition("En el café", "Pedir en un café o bar"));
        list.add(new LessonDefinition("Días de la semana", "Los siete días de la semana"));
        list.add(new LessonDefinition("El tiempo y las estaciones", "Hablar del clima y las estaciones"));
        list.add(new LessonDefinition("En la tienda", "Frases para compras y precios"));
        list.add(new LessonDefinition("Rutina diaria", "Verbos y frases del día a día"));
        list.add(new LessonDefinition("Partes del cuerpo", "Hablar del cuerpo humano"));
        list.add(new LessonDefinition("En el restaurante", "Pedir platos, bebidas y pagar la cuenta"));
        list.add(new LessonDefinition("Transporte", "Medios de transporte y direcciones"));
        list.add(new LessonDefinition("En el hotel", "Registro, habitaciones y servicios"));
        list.add(new LessonDefinition("Ocio y aficiones", "Hablar de hobbies y tiempo libre"));
        list.add(new LessonDefinition("En el trabajo", "Vocabulario laboral básico"));
        list.add(new LessonDefinition("Entrevista de trabajo", "Frases útiles para una entrevista"));
        list.add(new LessonDefinition("En el médico", "Describir síntomas y pedir ayuda"));
        list.add(new LessonDefinition("En el banco", "Abrir cuenta y hacer operaciones básicas"));
        list.add(new LessonDefinition("Tecnología e internet", "Términos digitales cotidianos"));
        list.add(new LessonDefinition("Expresar opiniones", "Estar de acuerdo o en desacuerdo"));
        list.add(new LessonDefinition("Dar consejos", "Recomendar y aconsejar con naturalidad"));
        list.add(new LessonDefinition("El pasado reciente", "Hablar de lo que hiciste ayer"));
        list.add(new LessonDefinition("Planes futuros", "Contar lo que vas a hacer mañana"));
        list.add(new LessonDefinition("Comparaciones", "Usar más que, menos que, tan como"));
        list.add(new LessonDefinition("Condicional y cortesía", "Hacer pedidos educados"));
        list.add(new LessonDefinition("Cocina y recetas", "Ingredientes y verbos de cocina"));
        list.add(new LessonDefinition("Cine y cultura", "Hablar de películas, series y libros"));
        list.add(new LessonDefinition("Noticias y medios", "Comentar la actualidad y las noticias"));
        list.add(new LessonDefinition("Repaso general", "Consolidar y repasar lo aprendido"));
        return list;
    }

    private record LessonDefinition(String title, String description) {
    }
}

