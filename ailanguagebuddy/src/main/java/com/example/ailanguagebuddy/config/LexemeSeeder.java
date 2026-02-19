package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.model.Lexeme;
import com.example.ailanguagebuddy.repository.LexemeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Seeds the lexemes table with Spanish vocabulary per theme (production content).
 * Seeds lexemes for all supported app languages when missing.
 */
@Component
@Order(1) // After LessonSeeder so lessons (and theme_key) exist
public class LexemeSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(LexemeSeeder.class);
    private static final List<String> SUPPORTED_LANGUAGES = List.of(
            "en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"
    );
    private static final String ES = "es";

    private final LexemeRepository lexemeRepository;

    public LexemeSeeder(LexemeRepository lexemeRepository) {
        this.lexemeRepository = lexemeRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        for (String lang : SUPPORTED_LANGUAGES) {
            if (lexemeRepository.countByLanguageCode(lang) > 0) {
                continue;
            }
            List<Lexeme> all = new ArrayList<>();
            if ("es".equalsIgnoreCase(lang)) {
                log.info("Seeding Spanish lexemes (production vocabulary in DB).");
                all.addAll(spanishGreetings());
                all.addAll(spanishNumbersColors());
                all.addAll(spanishFamily());
                all.addAll(spanishFood());
                all.addAll(spanishRoutine());
                all.addAll(spanishTravel());
                all.addAll(spanishCommunication());
                all.addAll(spanishReview());
            } else {
                log.info("Seeding {} lexemes (production vocabulary in DB).", lang);
                all.addAll(genericGreetings(lang));
                all.addAll(genericNumbersColors(lang));
                all.addAll(genericFamily(lang));
                all.addAll(genericFood(lang));
                all.addAll(genericRoutine(lang));
                all.addAll(genericTravel(lang));
                all.addAll(genericCommunication(lang));
                all.addAll(genericReview(lang));
            }
            lexemeRepository.saveAll(all);
            log.info("Seeded {} lexemes for language_code={}.", all.size(), lang);
        }
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

    private static List<String> tokens(String phrase) {
        if (phrase == null || phrase.isBlank()) return List.of();
        return Arrays.stream(phrase.trim().split("\\s+")).toList();
    }

    private record Tr(
            String hello, String helloPhrase,
            String goodbye, String goodbyePhrase,
            String please, String pleasePhrase,
            String thanks, String thanksPhrase,
            String one, String onePhrase,
            String two, String twoPhrase,
            String three, String threePhrase,
            String red, String redPhrase,
            String blue, String bluePhrase,
            String green, String greenPhrase,
            String mother, String motherPhrase,
            String father, String fatherPhrase,
            String friend, String friendPhrase,
            String love, String lovePhrase,
            String coffee, String coffeePhrase,
            String tea, String teaPhrase,
            String water, String waterPhrase,
            String bread, String breadPhrase,
            String food, String foodPhrase,
            String today, String todayPhrase,
            String tomorrow, String tomorrowPhrase,
            String time, String timePhrase,
            String work, String workPhrase,
            String house, String housePhrase,
            String train, String trainPhrase,
            String hotel, String hotelPhrase,
            String doctor, String doctorPhrase,
            String money, String moneyPhrase,
            String problem, String problemPhrase,
            String help, String helpPhrase,
            String book, String bookPhrase
    ) {}

    private static Tr tr(String lang) {
        String l = (lang == null ? "en" : lang.toLowerCase(Locale.ROOT));
        return switch (l) {
            case "fr" -> new Tr(
                    "bonjour", "Bonjour, comment ça va ?",
                    "au revoir", "À bientôt",
                    "s'il vous plaît", "Un café s'il vous plaît",
                    "merci", "Merci beaucoup",
                    "un", "Un billet",
                    "deux", "Deux cafés",
                    "trois", "Trois livres",
                    "rouge", "La voiture rouge",
                    "bleu", "Le ciel bleu",
                    "vert", "L'arbre vert",
                    "mère", "Ma mère",
                    "père", "Mon père travaille",
                    "ami", "Un bon ami",
                    "amour", "J'aime le français",
                    "un café", "Je voudrais un café",
                    "un thé", "Je voudrais un thé",
                    "de l'eau", "Je bois de l'eau",
                    "du pain", "Le pain est bon",
                    "la nourriture", "La nourriture est bonne",
                    "aujourd'hui", "Aujourd'hui, il pleut",
                    "demain", "À demain",
                    "heure", "Quelle heure est-il ?",
                    "travail", "Je travaille beaucoup",
                    "maison", "Ma maison est grande",
                    "train", "Le train arrive",
                    "hôtel", "Une chambre à l'hôtel",
                    "médecin", "J'ai besoin d'un médecin",
                    "argent", "J'ai besoin d'argent",
                    "problème", "Pas de problème",
                    "aide", "J'ai besoin d'aide",
                    "livre", "Je lis un livre"
            );
            case "de" -> new Tr(
                    "hallo", "Hallo, wie geht's?",
                    "tschüss", "Bis später",
                    "bitte", "Einen Kaffee bitte",
                    "danke", "Vielen Dank",
                    "eins", "Ein Ticket",
                    "zwei", "Zwei Kaffees",
                    "drei", "Drei Bücher",
                    "rot", "Das rote Auto",
                    "blau", "Der blaue Himmel",
                    "grün", "Der grüne Baum",
                    "Mutter", "Meine Mutter",
                    "Vater", "Mein Vater arbeitet",
                    "Freund", "Ein guter Freund",
                    "Liebe", "Ich liebe Deutsch",
                    "ein Kaffee", "Ich möchte einen Kaffee",
                    "ein Tee", "Ich möchte einen Tee",
                    "Wasser", "Ich trinke Wasser",
                    "Brot", "Das Brot ist gut",
                    "Essen", "Das Essen ist gut",
                    "heute", "Heute regnet es",
                    "morgen", "Bis morgen",
                    "Uhrzeit", "Wie spät ist es?",
                    "Arbeit", "Ich arbeite viel",
                    "Haus", "Mein Haus ist groß",
                    "Zug", "Der Zug kommt an",
                    "Hotel", "Ein Zimmer im Hotel",
                    "Arzt", "Ich brauche einen Arzt",
                    "Geld", "Ich brauche Geld",
                    "Problem", "Kein Problem",
                    "Hilfe", "Ich brauche Hilfe",
                    "Buch", "Ich lese ein Buch"
            );
            case "it" -> new Tr(
                    "ciao", "Ciao, come stai?",
                    "arrivederci", "A dopo",
                    "per favore", "Un caffè per favore",
                    "grazie", "Grazie mille",
                    "uno", "Un biglietto",
                    "due", "Due caffè",
                    "tre", "Tre libri",
                    "rosso", "La macchina rossa",
                    "blu", "Il cielo blu",
                    "verde", "L'albero verde",
                    "madre", "Mia madre",
                    "padre", "Mio padre lavora",
                    "amico", "Un buon amico",
                    "amore", "Amo l'italiano",
                    "un caffè", "Voglio un caffè",
                    "un tè", "Vorrei un tè",
                    "acqua", "Bevo acqua",
                    "pane", "Il pane è buono",
                    "cibo", "Il cibo è buono",
                    "oggi", "Oggi piove",
                    "domani", "A domani",
                    "ora", "Che ore sono?",
                    "lavoro", "Lavoro molto",
                    "casa", "La mia casa è grande",
                    "treno", "Il treno arriva",
                    "hotel", "Una stanza in hotel",
                    "medico", "Ho bisogno di un medico",
                    "soldi", "Ho bisogno di soldi",
                    "problema", "Nessun problema",
                    "aiuto", "Ho bisogno di aiuto",
                    "libro", "Leggo un libro"
            );
            case "pt" -> new Tr(
                    "olá", "Olá, como você está?",
                    "tchau", "Até logo",
                    "por favor", "Um café por favor",
                    "obrigado", "Muito obrigado",
                    "um", "Um bilhete",
                    "dois", "Dois cafés",
                    "três", "Três livros",
                    "vermelho", "O carro vermelho",
                    "azul", "O céu azul",
                    "verde", "A árvore verde",
                    "mãe", "Minha mãe",
                    "pai", "Meu pai trabalha",
                    "amigo", "Um bom amigo",
                    "amor", "Eu amo português",
                    "um café", "Eu quero um café",
                    "um chá", "Eu quero um chá",
                    "água", "Eu bebo água",
                    "pão", "O pão é bom",
                    "comida", "A comida é boa",
                    "hoje", "Hoje chove",
                    "amanhã", "Até amanhã",
                    "hora", "Que horas são?",
                    "trabalho", "Eu trabalho muito",
                    "casa", "Minha casa é grande",
                    "trem", "O trem chega",
                    "hotel", "Um quarto no hotel",
                    "médico", "Eu preciso de um médico",
                    "dinheiro", "Eu preciso de dinheiro",
                    "problema", "Sem problema",
                    "ajuda", "Eu preciso de ajuda",
                    "livro", "Eu leio um livro"
            );
            case "ru" -> new Tr(
                    "привет", "Привет, как дела?",
                    "пока", "До скорого",
                    "пожалуйста", "Кофе, пожалуйста",
                    "спасибо", "Большое спасибо",
                    "один", "Один билет",
                    "два", "Два кофе",
                    "три", "Три книги",
                    "красный", "Красная машина",
                    "синий", "Синее небо",
                    "зелёный", "Зелёное дерево",
                    "мама", "Моя мама",
                    "папа", "Мой папа работает",
                    "друг", "Хороший друг",
                    "любовь", "Я люблю русский",
                    "кофе", "Я хочу кофе",
                    "чай", "Я хочу чай",
                    "вода", "Я пью воду",
                    "хлеб", "Хлеб хороший",
                    "еда", "Еда вкусная",
                    "сегодня", "Сегодня дождь",
                    "завтра", "До завтра",
                    "время", "Который час?",
                    "работа", "Я много работаю",
                    "дом", "Мой дом большой",
                    "поезд", "Поезд прибывает",
                    "отель", "Номер в отеле",
                    "врач", "Мне нужен врач",
                    "деньги", "Мне нужны деньги",
                    "проблема", "Нет проблем",
                    "помощь", "Мне нужна помощь",
                    "книга", "Я читаю книгу"
            );
            case "ja" -> new Tr(
                    "こんにちは", "こんにちは 元気 です か",
                    "さようなら", "また あとで",
                    "お願いします", "コーヒー を お願いします",
                    "ありがとう", "どうも ありがとう",
                    "いち", "チケット ひとつ",
                    "に", "コーヒー ふたつ",
                    "さん", "本 みっつ",
                    "あか", "あかい 車",
                    "あお", "あおい 空",
                    "みどり", "みどり の 木",
                    "お母さん", "わたし の お母さん",
                    "お父さん", "わたし の お父さん は 仕事",
                    "友達", "いい 友達",
                    "愛", "日本語 が 好き",
                    "コーヒー", "コーヒー が ほしい",
                    "お茶", "お茶 が ほしい",
                    "水", "水 を 飲みます",
                    "パン", "パン は おいしい",
                    "食べ物", "食べ物 は おいしい",
                    "今日", "今日 は 雨",
                    "明日", "また 明日",
                    "時間", "今 何時 です か",
                    "仕事", "仕事 が たくさん",
                    "家", "わたし の 家 は 大きい",
                    "電車", "電車 が 来ます",
                    "ホテル", "ホテル の 部屋",
                    "医者", "医者 が 必要",
                    "お金", "お金 が 必要",
                    "問題", "問題 ない",
                    "助け", "助け が 必要",
                    "本", "本 を 読みます"
            );
            case "zh" -> new Tr(
                    "你好", "你 好 吗",
                    "再见", "待会 见",
                    "请", "请 给 我 咖啡",
                    "谢谢", "非常 谢谢",
                    "一", "一 张 票",
                    "二", "两 杯 咖啡",
                    "三", "三 本 书",
                    "红色", "红色 的 车",
                    "蓝色", "蓝色 的 天空",
                    "绿色", "绿色 的 树",
                    "妈妈", "我 的 妈妈",
                    "爸爸", "我 的 爸爸 工作",
                    "朋友", "好 朋友",
                    "爱", "我 喜欢 中文",
                    "咖啡", "我 想要 咖啡",
                    "茶", "我 想要 茶",
                    "水", "我 喝 水",
                    "面包", "面包 很 好吃",
                    "食物", "食物 很 好吃",
                    "今天", "今天 下雨",
                    "明天", "明天 见",
                    "时间", "现在 几点",
                    "工作", "我 工作 很 多",
                    "房子", "我 的 房子 很 大",
                    "火车", "火车 到 了",
                    "酒店", "酒店 的 房间",
                    "医生", "我 需要 医生",
                    "钱", "我 需要 钱",
                    "问题", "没 问题",
                    "帮助", "我 需要 帮助",
                    "书", "我 读 书"
            );
            default -> new Tr(
                    "hello", "Hello, how are you?",
                    "goodbye", "See you later",
                    "please", "One coffee please",
                    "thank you", "Thank you very much",
                    "one", "One ticket",
                    "two", "Two coffees",
                    "three", "Three books",
                    "red", "The red car",
                    "blue", "The blue sky",
                    "green", "The green tree",
                    "mother", "My mother",
                    "father", "My father works",
                    "friend", "A good friend",
                    "love", "I love English",
                    "coffee", "I want a coffee",
                    "tea", "I would like tea",
                    "water", "I drink water",
                    "bread", "The bread is good",
                    "food", "The food is good",
                    "today", "Today it rains",
                    "tomorrow", "See you tomorrow",
                    "time", "What time is it?",
                    "work", "I work a lot",
                    "house", "My house is big",
                    "train", "The train arrives",
                    "hotel", "A room in the hotel",
                    "doctor", "I need a doctor",
                    "money", "I need money",
                    "problem", "No problem",
                    "help", "I need help",
                    "book", "I read a book"
            );
        };
    }

    private List<Lexeme> genericGreetings(String lang) {
        Tr t = tr(lang);
        String theme = "greetings";
        return List.of(
                lex(lang, theme, "hello", "Hello, how are you?", t.hello, t.helloPhrase, tokens(t.helloPhrase), "👋", 0),
                lex(lang, theme, "goodbye", "See you later", t.goodbye, t.goodbyePhrase, tokens(t.goodbyePhrase), "👋", 1),
                lex(lang, theme, "please", "One coffee please", t.please, t.pleasePhrase, tokens(t.pleasePhrase), "🙏", 2),
                lex(lang, theme, "thank you", "Thank you very much", t.thanks, t.thanksPhrase, tokens(t.thanksPhrase), "🙏", 3)
        );
    }

    private List<Lexeme> genericNumbersColors(String lang) {
        Tr t = tr(lang);
        List<Lexeme> out = new ArrayList<>();
        out.add(lex(lang, "numbers", "one", "One ticket", t.one, t.onePhrase, tokens(t.onePhrase), "1️⃣", 0));
        out.add(lex(lang, "numbers", "two", "Two coffees", t.two, t.twoPhrase, tokens(t.twoPhrase), "2️⃣", 1));
        out.add(lex(lang, "numbers", "three", "Three books", t.three, t.threePhrase, tokens(t.threePhrase), "3️⃣", 2));
        out.add(lex(lang, "colors", "red", "The red car", t.red, t.redPhrase, tokens(t.redPhrase), "🔴", 0));
        out.add(lex(lang, "colors", "blue", "The blue sky", t.blue, t.bluePhrase, tokens(t.bluePhrase), "🔵", 1));
        out.add(lex(lang, "colors", "green", "The green tree", t.green, t.greenPhrase, tokens(t.greenPhrase), "🟢", 2));
        return out;
    }

    private List<Lexeme> genericFamily(String lang) {
        Tr t = tr(lang);
        String theme = "family";
        return List.of(
                lex(lang, theme, "mother", "My mother", t.mother, t.motherPhrase, tokens(t.motherPhrase), "👩", 0),
                lex(lang, theme, "father", "My father works", t.father, t.fatherPhrase, tokens(t.fatherPhrase), "👨", 1),
                lex(lang, theme, "friend", "A good friend", t.friend, t.friendPhrase, tokens(t.friendPhrase), "👫", 2),
                lex(lang, theme, "love", "I love this language", t.love, t.lovePhrase, tokens(t.lovePhrase), "❤️", 3)
        );
    }

    private List<Lexeme> genericFood(String lang) {
        Tr t = tr(lang);
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("food", "cafe", "restaurant")) {
            out.add(lex(lang, theme, "coffee", "I want a coffee", t.coffee, t.coffeePhrase, tokens(t.coffeePhrase), "☕", 0));
            out.add(lex(lang, theme, "tea", "I would like tea", t.tea, t.teaPhrase, tokens(t.teaPhrase), "🍵", 1));
            out.add(lex(lang, theme, "water", "I drink water", t.water, t.waterPhrase, tokens(t.waterPhrase), "💧", 2));
            out.add(lex(lang, theme, "bread", "The bread is good", t.bread, t.breadPhrase, tokens(t.breadPhrase), "🍞", 3));
            out.add(lex(lang, theme, "food", "The food is good", t.food, t.foodPhrase, tokens(t.foodPhrase), "🍽️", 4));
        }
        return out;
    }

    private List<Lexeme> genericRoutine(String lang) {
        Tr t = tr(lang);
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("days_weather", "shop", "routine", "body")) {
            out.add(lex(lang, theme, "today", "Today it rains", t.today, t.todayPhrase, tokens(t.todayPhrase), "☀️", 0));
            out.add(lex(lang, theme, "tomorrow", "See you tomorrow", t.tomorrow, t.tomorrowPhrase, tokens(t.tomorrowPhrase), "🌅", 1));
            out.add(lex(lang, theme, "time", "What time is it?", t.time, t.timePhrase, tokens(t.timePhrase), "🕐", 2));
            out.add(lex(lang, theme, "work", "I work a lot", t.work, t.workPhrase, tokens(t.workPhrase), "💼", 3));
            out.add(lex(lang, theme, "house", "My house is big", t.house, t.housePhrase, tokens(t.housePhrase), "🏠", 4));
        }
        return out;
    }

    private List<Lexeme> genericTravel(String lang) {
        Tr t = tr(lang);
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("transport", "hotel", "hobbies", "work", "interview", "doctor", "bank", "tech")) {
            out.add(lex(lang, theme, "train", "The train arrives", t.train, t.trainPhrase, tokens(t.trainPhrase), "🚂", 0));
            out.add(lex(lang, theme, "hotel", "A room in the hotel", t.hotel, t.hotelPhrase, tokens(t.hotelPhrase), "🏨", 1));
            out.add(lex(lang, theme, "doctor", "I need a doctor", t.doctor, t.doctorPhrase, tokens(t.doctorPhrase), "👨‍⚕️", 2));
            out.add(lex(lang, theme, "money", "I need money", t.money, t.moneyPhrase, tokens(t.moneyPhrase), "💰", 3));
        }
        return out;
    }

    private List<Lexeme> genericCommunication(String lang) {
        Tr t = tr(lang);
        List<Lexeme> out = new ArrayList<>();
        for (String theme : List.of("opinions", "advice", "past", "future", "comparisons", "conditional", "kitchen", "culture", "news")) {
            out.add(lex(lang, theme, "problem", "No problem", t.problem, t.problemPhrase, tokens(t.problemPhrase), "❓", 0));
            out.add(lex(lang, theme, "help", "I need help", t.help, t.helpPhrase, tokens(t.helpPhrase), "🆘", 1));
            out.add(lex(lang, theme, "book", "I read a book", t.book, t.bookPhrase, tokens(t.bookPhrase), "📖", 2));
            out.add(lex(lang, theme, "today", "Today it rains", t.today, t.todayPhrase, tokens(t.todayPhrase), "☀️", 3));
        }
        return out;
    }

    private List<Lexeme> genericReview(String lang) {
        Tr t = tr(lang);
        String theme = "review";
        return List.of(
                lex(lang, theme, "hello", "Hello, how are you?", t.hello, t.helloPhrase, tokens(t.helloPhrase), "👋", 0),
                lex(lang, theme, "coffee", "I want a coffee", t.coffee, t.coffeePhrase, tokens(t.coffeePhrase), "☕", 1),
                lex(lang, theme, "thank you", "Thank you very much", t.thanks, t.thanksPhrase, tokens(t.thanksPhrase), "🙏", 2),
                lex(lang, theme, "work", "I work a lot", t.work, t.workPhrase, tokens(t.workPhrase), "💼", 3)
        );
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
