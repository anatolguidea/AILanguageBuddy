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
 * Ensures 30 themed lessons per supported language. Content is generated from lexemes (DB).
 * Seeds or replaces lessons so each language has exactly TARGET_COUNT with theme_key set.
 */
@Component
@org.springframework.core.annotation.Order(0)
public class LessonSeeder implements ApplicationRunner {

    public static final int ORDER = 0;

    private static final Logger log = LoggerFactory.getLogger(LessonSeeder.class);
    private static final int TARGET_COUNT = 30;
    private static final List<String> SUPPORTED_LANGUAGES = List.of(
            "en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"
    );

    private final LessonRepository lessonRepository;

    public LessonSeeder(LessonRepository lessonRepository) {
        this.lessonRepository = lessonRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        for (String languageCode : SUPPORTED_LANGUAGES) {
            ensureCanonicalLessons(languageCode);
        }
    }

    private void ensureCanonicalLessons(String languageCode) {
        long existing = lessonRepository.countByLanguageCode(languageCode);
        List<Lesson> all = lessonRepository.findByLanguageCode(languageCode, org.springframework.data.domain.Sort.by("orderIndex"));
        boolean needThemeBackfill = all.stream().anyMatch(l -> l.getThemeKey() == null || l.getThemeKey().isBlank());

        if (existing != TARGET_COUNT) {
            if (existing > 0) {
                log.info("Replacing {} existing lessons with canonical {} for language_code={}.", existing, TARGET_COUNT, languageCode);
                lessonRepository.deleteByLanguageCode(languageCode);
            } else {
                log.info("Seeding {} lessons for language_code={}.", TARGET_COUNT, languageCode);
            }
            saveCanonicalLessons(languageCode);
        } else if (needThemeBackfill) {
            log.info("Backfilling theme_key for language_code={} on {} lessons.", languageCode, all.size());
            applyThemeKeysByOrder(all);
            lessonRepository.saveAll(all);
        }
    }

    private void applyThemeKeysByOrder(List<Lesson> lessons) {
        for (int i = 0; i < lessons.size() && i < THEME_KEYS.length; i++) {
            lessons.get(i).setThemeKey(THEME_KEYS[i]);
        }
    }

    private void saveCanonicalLessons(String languageCode) {
        List<LessonDefinition> definitions = getDefinitions(languageCode);
        List<Lesson> toSave = new ArrayList<>();
        for (int i = 0; i < definitions.size(); i++) {
            LessonDefinition def = definitions.get(i);
            int orderIndex = i + 1;
            String themeKey = i < THEME_KEYS.length ? THEME_KEYS[i] : "review";
            Lesson lesson = Lesson.builder()
                    .languageCode(languageCode)
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
        log.info("Seeded {} lessons (language_code = {}).", toSave.size(), languageCode);
    }

    /** Theme keys for production: lesson challenges load lexemes from DB by (language_code, theme_key). */
    private static final String[] THEME_KEYS = {
            "greetings", "numbers", "colors", "family", "food", "cafe", "days_weather", "shop", "routine",
            "body", "restaurant", "transport", "hotel", "hobbies", "work", "interview", "doctor", "bank",
            "tech", "opinions", "advice", "past", "future", "comparisons", "conditional", "kitchen", "culture",
            "news", "review", "review"
    };

    /** Returns 30 (title, description) pairs for the given language. */
    private List<LessonDefinition> getDefinitions(String languageCode) {
        String lang = languageCode == null ? "en" : languageCode.toLowerCase();
        return switch (lang) {
            case "es" -> spanishDefinitions();
            case "fr" -> frenchDefinitions();
            case "de" -> germanDefinitions();
            case "it" -> italianDefinitions();
            case "pt" -> portugueseDefinitions();
            case "ru" -> russianDefinitions();
            case "ja" -> japaneseDefinitions();
            case "zh" -> chineseDefinitions();
            default -> englishDefinitions();
        };
    }

    private List<LessonDefinition> englishDefinitions() {
        return List.of(
                new LessonDefinition("Greetings and introductions", "Learn to greet and introduce yourself"),
                new LessonDefinition("Numbers 1 to 10", "Count and use basic numbers"),
                new LessonDefinition("Basic colors", "Name colors"),
                new LessonDefinition("The family", "Vocabulary for family members"),
                new LessonDefinition("Food and drink", "Words for eating and drinking"),
                new LessonDefinition("At the café", "Order at a café or bar"),
                new LessonDefinition("Days of the week", "The seven days of the week"),
                new LessonDefinition("Weather and seasons", "Talk about the weather"),
                new LessonDefinition("At the shop", "Phrases for shopping and prices"),
                new LessonDefinition("Daily routine", "Verbs and phrases for the day"),
                new LessonDefinition("Parts of the body", "The human body"),
                new LessonDefinition("At the restaurant", "Order dishes and pay the bill"),
                new LessonDefinition("Transport", "Transport and directions"),
                new LessonDefinition("At the hotel", "Check-in and rooms"),
                new LessonDefinition("Leisure and hobbies", "Talk about hobbies"),
                new LessonDefinition("At work", "Basic work vocabulary"),
                new LessonDefinition("Job interview", "Useful phrases for an interview"),
                new LessonDefinition("At the doctor", "Describe symptoms and ask for help"),
                new LessonDefinition("At the bank", "Open an account and basic operations"),
                new LessonDefinition("Technology and internet", "Everyday digital terms"),
                new LessonDefinition("Expressing opinions", "Agree or disagree"),
                new LessonDefinition("Giving advice", "Recommend and advise"),
                new LessonDefinition("Recent past", "What you did yesterday"),
                new LessonDefinition("Future plans", "What you are going to do tomorrow"),
                new LessonDefinition("Comparisons", "More than, less than, as... as"),
                new LessonDefinition("Conditional and politeness", "Polite requests"),
                new LessonDefinition("Kitchen and recipes", "Ingredients and cooking verbs"),
                new LessonDefinition("Cinema and culture", "Films, series and books"),
                new LessonDefinition("News and media", "Comment on the news"),
                new LessonDefinition("General review", "Consolidate what you have learned")
        );
    }

    private List<LessonDefinition> spanishDefinitions() {
        return List.of(
                new LessonDefinition("Saludos y presentaciones", "Aprende a saludar y presentarte en español"),
                new LessonDefinition("Números del 1 al 10", "Cuenta y usa los números básicos"),
                new LessonDefinition("Colores básicos", "Nombra los colores en español"),
                new LessonDefinition("La familia", "Vocabulario de los miembros de la familia"),
                new LessonDefinition("Comida y bebida", "Palabras para comer y beber"),
                new LessonDefinition("En el café", "Pedir en un café o bar"),
                new LessonDefinition("Días de la semana", "Los siete días de la semana"),
                new LessonDefinition("El tiempo y las estaciones", "Hablar del clima y las estaciones"),
                new LessonDefinition("En la tienda", "Frases para compras y precios"),
                new LessonDefinition("Rutina diaria", "Verbos y frases del día a día"),
                new LessonDefinition("Partes del cuerpo", "Hablar del cuerpo humano"),
                new LessonDefinition("En el restaurante", "Pedir platos, bebidas y pagar la cuenta"),
                new LessonDefinition("Transporte", "Medios de transporte y direcciones"),
                new LessonDefinition("En el hotel", "Registro, habitaciones y servicios"),
                new LessonDefinition("Ocio y aficiones", "Hablar de hobbies y tiempo libre"),
                new LessonDefinition("En el trabajo", "Vocabulario laboral básico"),
                new LessonDefinition("Entrevista de trabajo", "Frases útiles para una entrevista"),
                new LessonDefinition("En el médico", "Describir síntomas y pedir ayuda"),
                new LessonDefinition("En el banco", "Abrir cuenta y hacer operaciones básicas"),
                new LessonDefinition("Tecnología e internet", "Términos digitales cotidianos"),
                new LessonDefinition("Expresar opiniones", "Estar de acuerdo o en desacuerdo"),
                new LessonDefinition("Dar consejos", "Recomendar y aconsejar con naturalidad"),
                new LessonDefinition("El pasado reciente", "Hablar de lo que hiciste ayer"),
                new LessonDefinition("Planes futuros", "Contar lo que vas a hacer mañana"),
                new LessonDefinition("Comparaciones", "Usar más que, menos que, tan como"),
                new LessonDefinition("Condicional y cortesía", "Hacer pedidos educados"),
                new LessonDefinition("Cocina y recetas", "Ingredientes y verbos de cocina"),
                new LessonDefinition("Cine y cultura", "Hablar de películas, series y libros"),
                new LessonDefinition("Noticias y medios", "Comentar la actualidad y las noticias"),
                new LessonDefinition("Repaso general", "Consolidar y repasar lo aprendido")
        );
    }

    private List<LessonDefinition> frenchDefinitions() {
        return List.of(
                new LessonDefinition("Salutations et présentations", "Apprendre à saluer et se présenter"),
                new LessonDefinition("Les nombres de 1 à 10", "Compter et utiliser les nombres de base"),
                new LessonDefinition("Les couleurs de base", "Nommer les couleurs"),
                new LessonDefinition("La famille", "Vocabulaire des membres de la famille"),
                new LessonDefinition("Nourriture et boissons", "Mots pour manger et boire"),
                new LessonDefinition("Au café", "Commander au café ou au bar"),
                new LessonDefinition("Les jours de la semaine", "Les sept jours de la semaine"),
                new LessonDefinition("Le temps et les saisons", "Parler de la météo"),
                new LessonDefinition("Au magasin", "Phrases pour les courses et les prix"),
                new LessonDefinition("Routine quotidienne", "Verbes et phrases du quotidien"),
                new LessonDefinition("Les parties du corps", "Le corps humain"),
                new LessonDefinition("Au restaurant", "Commander et payer l'addition"),
                new LessonDefinition("Les transports", "Moyens de transport et directions"),
                new LessonDefinition("À l'hôtel", "Enregistrement et chambres"),
                new LessonDefinition("Loisirs et hobbies", "Parler des loisirs"),
                new LessonDefinition("Au travail", "Vocabulaire professionnel de base"),
                new LessonDefinition("Entretien d'embauche", "Phrases utiles pour un entretien"),
                new LessonDefinition("Chez le médecin", "Décrire les symptômes"),
                new LessonDefinition("À la banque", "Ouvrir un compte et opérations de base"),
                new LessonDefinition("Technologie et internet", "Termes numériques du quotidien"),
                new LessonDefinition("Exprimer son avis", "Être d'accord ou pas"),
                new LessonDefinition("Donner des conseils", "Recommander et conseiller"),
                new LessonDefinition("Le passé récent", "Ce que vous avez fait hier"),
                new LessonDefinition("Projets futurs", "Ce que vous allez faire demain"),
                new LessonDefinition("Les comparaisons", "Plus que, moins que, aussi... que"),
                new LessonDefinition("Conditionnel et politesse", "Demandes polies"),
                new LessonDefinition("Cuisine et recettes", "Ingrédients et verbes de cuisine"),
                new LessonDefinition("Cinéma et culture", "Films, séries et livres"),
                new LessonDefinition("Actualités et médias", "Commenter l'actualité"),
                new LessonDefinition("Révision générale", "Consolider ce que vous avez appris")
        );
    }

    private List<LessonDefinition> germanDefinitions() {
        return List.of(
                new LessonDefinition("Begrüßungen und Vorstellungen", "Grüßen und sich vorstellen"),
                new LessonDefinition("Zahlen 1 bis 10", "Zählen und Grundzahlen verwenden"),
                new LessonDefinition("Grundfarben", "Farben benennen"),
                new LessonDefinition("Die Familie", "Wortschatz für Familienmitglieder"),
                new LessonDefinition("Essen und Trinken", "Wörter zum Essen und Trinken"),
                new LessonDefinition("Im Café", "Im Café oder an der Bar bestellen"),
                new LessonDefinition("Wochentage", "Die sieben Wochentage"),
                new LessonDefinition("Wetter und Jahreszeiten", "Über das Wetter sprechen"),
                new LessonDefinition("Im Geschäft", "Phrasen zum Einkaufen und Preise"),
                new LessonDefinition("Tagesablauf", "Verben und Sätze für den Alltag"),
                new LessonDefinition("Körperteile", "Der menschliche Körper"),
                new LessonDefinition("Im Restaurant", "Gerichte bestellen und zahlen"),
                new LessonDefinition("Transport", "Verkehrsmittel und Wegbeschreibungen"),
                new LessonDefinition("Im Hotel", "Check-in und Zimmer"),
                new LessonDefinition("Freizeit und Hobbys", "Über Hobbys sprechen"),
                new LessonDefinition("Bei der Arbeit", "Grundlegender Berufswortschatz"),
                new LessonDefinition("Vorstellungsgespräch", "Nützliche Phrasen für ein Gespräch"),
                new LessonDefinition("Beim Arzt", "Symptome beschreiben"),
                new LessonDefinition("In der Bank", "Konto eröffnen und Grundlagen"),
                new LessonDefinition("Technologie und Internet", "Alltägliche digitale Begriffe"),
                new LessonDefinition("Meinungen äußern", "Zustimmen oder widersprechen"),
                new LessonDefinition("Ratschläge geben", "Empfehlen und beraten"),
                new LessonDefinition("Das letzte Mal", "Was du gestern gemacht hast"),
                new LessonDefinition("Zukunftspläne", "Was du morgen machen wirst"),
                new LessonDefinition("Vergleiche", "Mehr als, weniger als, so... wie"),
                new LessonDefinition("Konditional und Höflichkeit", "Höfliche Bitten"),
                new LessonDefinition("Küche und Rezepte", "Zutaten und Kochverben"),
                new LessonDefinition("Kino und Kultur", "Filme, Serien und Bücher"),
                new LessonDefinition("Nachrichten und Medien", "Über die Nachrichten sprechen"),
                new LessonDefinition("Allgemeine Wiederholung", "Gelerntes festigen")
        );
    }

    private List<LessonDefinition> italianDefinitions() {
        return List.of(
                new LessonDefinition("Saluti e presentazioni", "Imparare a salutare e presentarsi"),
                new LessonDefinition("Numeri da 1 a 10", "Contare e usare i numeri base"),
                new LessonDefinition("Colori base", "Nominare i colori"),
                new LessonDefinition("La famiglia", "Vocabolario dei familiari"),
                new LessonDefinition("Cibo e bevande", "Parole per mangiare e bere"),
                new LessonDefinition("Al bar", "Ordinare al bar"),
                new LessonDefinition("Giorni della settimana", "I sette giorni della settimana"),
                new LessonDefinition("Tempo e stagioni", "Parlare del tempo"),
                new LessonDefinition("Al negozio", "Frasi per acquisti e prezzi"),
                new LessonDefinition("Routine quotidiana", "Verbi e frasi del giorno"),
                new LessonDefinition("Parti del corpo", "Il corpo umano"),
                new LessonDefinition("Al ristorante", "Ordinare e pagare il conto"),
                new LessonDefinition("Trasporti", "Mezzi e indicazioni"),
                new LessonDefinition("In hotel", "Check-in e camere"),
                new LessonDefinition("Tempo libero e hobby", "Parlare di hobby"),
                new LessonDefinition("Al lavoro", "Vocabolario lavorativo base"),
                new LessonDefinition("Colloquio di lavoro", "Frasi utili per un colloquio"),
                new LessonDefinition("Dal medico", "Descrivere i sintomi"),
                new LessonDefinition("In banca", "Aprire un conto e operazioni base"),
                new LessonDefinition("Tecnologia e internet", "Termini digitali quotidiani"),
                new LessonDefinition("Esprimere opinioni", "Essere d'accordo o no"),
                new LessonDefinition("Dare consigli", "Raccomandare e consigliare"),
                new LessonDefinition("Passato prossimo", "Cosa hai fatto ieri"),
                new LessonDefinition("Piani futuri", "Cosa farai domani"),
                new LessonDefinition("Comparazioni", "Più di, meno di, tanto... quanto"),
                new LessonDefinition("Condizionale e cortesia", "Richieste educate"),
                new LessonDefinition("Cucina e ricette", "Ingredienti e verbi di cucina"),
                new LessonDefinition("Cinema e cultura", "Film, serie e libri"),
                new LessonDefinition("Notizie e media", "Commentare l'attualità"),
                new LessonDefinition("Ripasso generale", "Consolidare ciò che hai imparato")
        );
    }

    private List<LessonDefinition> portugueseDefinitions() {
        return List.of(
                new LessonDefinition("Saudações e apresentações", "Aprender a cumprimentar e se apresentar"),
                new LessonDefinition("Números de 1 a 10", "Contar e usar números básicos"),
                new LessonDefinition("Cores básicas", "Nomear as cores"),
                new LessonDefinition("A família", "Vocabulário dos membros da família"),
                new LessonDefinition("Comida e bebida", "Palavras para comer e beber"),
                new LessonDefinition("No café", "Pedir no café ou bar"),
                new LessonDefinition("Dias da semana", "Os sete dias da semana"),
                new LessonDefinition("Tempo e estações", "Falar do clima"),
                new LessonDefinition("Na loja", "Frases para compras e preços"),
                new LessonDefinition("Rotina diária", "Verbos e frases do dia a dia"),
                new LessonDefinition("Partes do corpo", "O corpo humano"),
                new LessonDefinition("No restaurante", "Pedir pratos e pagar a conta"),
                new LessonDefinition("Transporte", "Meios de transporte e direções"),
                new LessonDefinition("No hotel", "Check-in e quartos"),
                new LessonDefinition("Lazer e hobbies", "Falar de hobbies"),
                new LessonDefinition("No trabalho", "Vocabulário profissional básico"),
                new LessonDefinition("Entrevista de emprego", "Frases úteis para entrevista"),
                new LessonDefinition("No médico", "Descrever sintomas"),
                new LessonDefinition("No banco", "Abrir conta e operações básicas"),
                new LessonDefinition("Tecnologia e internet", "Termos digitais do dia a dia"),
                new LessonDefinition("Expressar opiniões", "Concordar ou discordar"),
                new LessonDefinition("Dar conselhos", "Recomendar e aconselhar"),
                new LessonDefinition("Passado recente", "O que você fez ontem"),
                new LessonDefinition("Planos futuros", "O que você vai fazer amanhã"),
                new LessonDefinition("Comparações", "Mais que, menos que, tão... quanto"),
                new LessonDefinition("Condicional e cortesia", "Pedidos educados"),
                new LessonDefinition("Cozinha e receitas", "Ingredientes e verbos de cozinha"),
                new LessonDefinition("Cinema e cultura", "Filmes, séries e livros"),
                new LessonDefinition("Notícias e mídia", "Comentar a atualidade"),
                new LessonDefinition("Revisão geral", "Consolidar o que aprendeu")
        );
    }

    private List<LessonDefinition> russianDefinitions() {
        return List.of(
                new LessonDefinition("Приветствия и представления", "Учимся здороваться и представляться"),
                new LessonDefinition("Числа от 1 до 10", "Считаем и используем базовые числа"),
                new LessonDefinition("Основные цвета", "Названия цветов"),
                new LessonDefinition("Семья", "Слова для членов семьи"),
                new LessonDefinition("Еда и напитки", "Слова для еды и питья"),
                new LessonDefinition("В кафе", "Заказ в кафе или баре"),
                new LessonDefinition("Дни недели", "Семь дней недели"),
                new LessonDefinition("Погода и времена года", "Говорим о погоде"),
                new LessonDefinition("В магазине", "Фразы для покупок и цен"),
                new LessonDefinition("Ежедневная рутина", "Глаголы и фразы на каждый день"),
                new LessonDefinition("Части тела", "Тело человека"),
                new LessonDefinition("В ресторане", "Заказ блюд и оплата"),
                new LessonDefinition("Транспорт", "Транспорт и направления"),
                new LessonDefinition("В отеле", "Регистрация и номера"),
                new LessonDefinition("Досуг и хобби", "Говорим о хобби"),
                new LessonDefinition("На работе", "Базовая рабочая лексика"),
                new LessonDefinition("Собеседование", "Полезные фразы для собеседования"),
                new LessonDefinition("У врача", "Описание симптомов"),
                new LessonDefinition("В банке", "Открытие счёта и операции"),
                new LessonDefinition("Технологии и интернет", "Повседневные цифровые термины"),
                new LessonDefinition("Выражение мнения", "Согласие или несогласие"),
                new LessonDefinition("Советы", "Рекомендовать и советовать"),
                new LessonDefinition("Недавнее прошлое", "Что вы делали вчера"),
                new LessonDefinition("Планы на будущее", "Что вы будете делать завтра"),
                new LessonDefinition("Сравнения", "Больше чем, меньше чем, так же как"),
                new LessonDefinition("Условность и вежливость", "Вежливые просьбы"),
                new LessonDefinition("Кухня и рецепты", "Ингредиенты и глаголы готовки"),
                new LessonDefinition("Кино и культура", "Фильмы, сериалы и книги"),
                new LessonDefinition("Новости и медиа", "Комментировать новости"),
                new LessonDefinition("Общее повторение", "Закрепить изученное")
        );
    }

    private List<LessonDefinition> japaneseDefinitions() {
        return List.of(
                new LessonDefinition("挨拶と自己紹介", "挨拶と自己紹介を学ぶ"),
                new LessonDefinition("数字 1 から 10", "数字を数えて使う"),
                new LessonDefinition("基本的な色", "色の名前"),
                new LessonDefinition("家族", "家族の語彙"),
                new LessonDefinition("食べ物と飲み物", "食べる・飲むための言葉"),
                new LessonDefinition("カフェで", "カフェやバーで注文"),
                new LessonDefinition("曜日", "一週間の七日"),
                new LessonDefinition("天気と季節", "天気について話す"),
                new LessonDefinition("お店で", "買い物と値段の表現"),
                new LessonDefinition("日常のルーティン", "一日の動詞と表現"),
                new LessonDefinition("体の部分", "体の部位"),
                new LessonDefinition("レストランで", "注文と会計"),
                new LessonDefinition("交通", "交通手段と道案内"),
                new LessonDefinition("ホテルで", "チェックインと部屋"),
                new LessonDefinition("趣味と余暇", "趣味について話す"),
                new LessonDefinition("仕事で", "基本的な仕事の語彙"),
                new LessonDefinition("面接", "面接で使う表現"),
                new LessonDefinition("病院で", "症状を説明する"),
                new LessonDefinition("銀行で", "口座開設と基本操作"),
                new LessonDefinition("テクノロジーとインターネット", "日常のデジタル用語"),
                new LessonDefinition("意見を言う", "賛成・反対"),
                new LessonDefinition("アドバイスする", "勧める・助言する"),
                new LessonDefinition("最近の過去", "昨日したこと"),
                new LessonDefinition("将来の計画", "明日すること"),
                new LessonDefinition("比較", "より多い、より少ない、同じくらい"),
                new LessonDefinition("条件と丁寧さ", "丁寧な依頼"),
                new LessonDefinition("料理とレシピ", "材料と調理の動詞"),
                new LessonDefinition("映画と文化", "映画、ドラマ、本"),
                new LessonDefinition("ニュースとメディア", "ニュースについて話す"),
                new LessonDefinition("総復習", "学んだことを定着させる")
        );
    }

    private List<LessonDefinition> chineseDefinitions() {
        return List.of(
                new LessonDefinition("问候与介绍", "学习打招呼和自我介绍"),
                new LessonDefinition("数字 1 到 10", "数数和基本数字"),
                new LessonDefinition("基本颜色", "颜色的名称"),
                new LessonDefinition("家庭", "家庭成员词汇"),
                new LessonDefinition("食物和饮料", "吃喝相关词汇"),
                new LessonDefinition("在咖啡馆", "在咖啡馆或酒吧点单"),
                new LessonDefinition("星期", "一周七天"),
                new LessonDefinition("天气和季节", "谈论天气"),
                new LessonDefinition("在商店", "购物和价格用语"),
                new LessonDefinition("日常作息", "一天的动词和短语"),
                new LessonDefinition("身体部位", "人体部位"),
                new LessonDefinition("在餐厅", "点菜和结账"),
                new LessonDefinition("交通", "交通工具和问路"),
                new LessonDefinition("在酒店", "入住和房间"),
                new LessonDefinition("休闲与爱好", "谈论爱好"),
                new LessonDefinition("在工作", "基本工作词汇"),
                new LessonDefinition("求职面试", "面试常用语"),
                new LessonDefinition("看医生", "描述症状"),
                new LessonDefinition("在银行", "开户和基本业务"),
                new LessonDefinition("科技与网络", "日常数字用语"),
                new LessonDefinition("表达观点", "同意或不同意"),
                new LessonDefinition("给出建议", "推荐和建议"),
                new LessonDefinition("最近过去", "昨天做了什么"),
                new LessonDefinition("未来计划", "明天要做什么"),
                new LessonDefinition("比较", "比……多、少、一样"),
                new LessonDefinition("条件与礼貌", "礼貌请求"),
                new LessonDefinition("厨房与食谱", "食材和烹饪动词"),
                new LessonDefinition("电影与文化", "电影、剧集和书"),
                new LessonDefinition("新闻与媒体", "评论时事"),
                new LessonDefinition("总复习", "巩固所学")
        );
    }

    private record LessonDefinition(String title, String description) {
    }
}
