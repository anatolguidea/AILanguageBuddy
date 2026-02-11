import '../domain/entities/lesson.dart';
import '../domain/entities/exercise.dart';

/// Static catalog of lessons for all supported languages.
/// Mixes ArrangeWords, Translate and MultipleChoice exercises.
/// Status defaults to [LessonStatus.locked] — the repository
/// overrides it based on persisted progress.
class LocalLessonsCatalog {
  const LocalLessonsCatalog._();

  static List<Lesson> forLanguage(String languageCode) {
    final lessons = _catalog[languageCode];
    return lessons ?? _catalog['en']!;
  }

  // ─── Helpers ─────────────────────────────────────────────
  static ArrangeWordsExercise _arrange({
    required String id,
    required String prompt,
    String hint = '',
    required List<String> words,
    required List<String> solution,
    String? foreignPhrase,
  }) =>
      ArrangeWordsExercise(
        id: id, prompt: prompt, hint: hint,
        words: words, solution: solution,
        foreignPhrase: foreignPhrase,
      );

  static TranslateExercise _translate({
    required String id,
    required String prompt,
    required String foreignPhrase,
    required List<String> wordBank,
    required List<String> solution,
  }) =>
      TranslateExercise(
        id: id, prompt: prompt,
        foreignPhrase: foreignPhrase,
        wordBank: wordBank, solution: solution,
      );

  static MultipleChoiceExercise _choice({
    required String id,
    required String prompt,
    required List<ChoiceOption> options,
    required int correctIndex,
  }) =>
      MultipleChoiceExercise(
        id: id, prompt: prompt,
        options: options, correctOptionIndex: correctIndex,
      );

  // ─── Catalog ─────────────────────────────────────────────
  static final Map<String, List<Lesson>> _catalog = {

    // ═══════════════  SPANISH  ═══════════════
    'es': [
      Lesson(
        id: 'es-1', title: 'Saludos', description: 'Basic greetings in Spanish.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'es',
        exercises: [
          _translate(
            id: 'es-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Hola, ¿cómo estás?',
            wordBank: ['are', 'Hello,', 'you', 'how', 'is', 'we'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'es-1-2',
            prompt: 'Which one of these is "hello"?',
            options: [
              const ChoiceOption(label: 'hola', emoji: '👋'),
              const ChoiceOption(label: 'adiós', emoji: '🚪'),
              const ChoiceOption(label: 'gracias', emoji: '🙏'),
            ],
            correctIndex: 0,
          ),
          _arrange(
            id: 'es-1-3',
            prompt: 'Arrange: Buenos días a todos',
            foreignPhrase: 'Buenos días a todos',
            words: ['a', 'Buenos', 'todos', 'días'],
            solution: ['Buenos', 'días', 'a', 'todos'],
          ),
        ],
      ),
      Lesson(
        id: 'es-2', title: 'Presentación', description: 'Introduce yourself.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'es',
        exercises: [
          _translate(
            id: 'es-2-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Me llamo Ana',
            wordBank: ['name', 'My', 'Ana', 'is', 'has', 'the'],
            solution: ['My', 'name', 'is', 'Ana'],
          ),
          _choice(
            id: 'es-2-2',
            prompt: 'Which one of these is "name"?',
            options: [
              const ChoiceOption(label: 'casa', emoji: '🏠'),
              const ChoiceOption(label: 'nombre', emoji: '📛'),
              const ChoiceOption(label: 'perro', emoji: '🐕'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'es-2-3',
            prompt: 'Arrange: Mucho gusto en conocerte',
            foreignPhrase: 'Mucho gusto en conocerte',
            words: ['conocerte', 'en', 'Mucho', 'gusto'],
            solution: ['Mucho', 'gusto', 'en', 'conocerte'],
          ),
        ],
      ),
      Lesson(
        id: 'es-3', title: 'Comida y Bebida', description: 'Food and drink vocabulary.',
        status: LessonStatus.locked, orderIndex: 3, languageCode: 'es',
        exercises: [
          _choice(
            id: 'es-3-1',
            prompt: 'Which one of these is "coffee"?',
            options: [
              const ChoiceOption(label: 'un café', emoji: '☕'),
              const ChoiceOption(label: 'un croissant', emoji: '🥐'),
              const ChoiceOption(label: 'un té', emoji: '🍵'),
            ],
            correctIndex: 0,
          ),
          _translate(
            id: 'es-3-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Quiero un café, por favor',
            wordBank: ['a', 'want', 'I', 'coffee', 'please', 'need', 'tea'],
            solution: ['I', 'want', 'a', 'coffee', 'please'],
          ),
          _choice(
            id: 'es-3-3',
            prompt: 'Which one of these is "water"?',
            options: [
              const ChoiceOption(label: 'leche', emoji: '🥛'),
              const ChoiceOption(label: 'agua', emoji: '💧'),
              const ChoiceOption(label: 'jugo', emoji: '🧃'),
              const ChoiceOption(label: 'vino', emoji: '🍷'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'es-4', title: 'Rutina Diaria', description: 'Daily routine verbs.',
        status: LessonStatus.locked, orderIndex: 4, languageCode: 'es',
        exercises: [
          _translate(
            id: 'es-4-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Yo desayuno a las ocho',
            wordBank: ['eat', 'at', 'breakfast', 'I', 'eight', 'lunch', 'noon'],
            solution: ['I', 'eat', 'breakfast', 'at', 'eight'],
          ),
          _arrange(
            id: 'es-4-2',
            prompt: 'Arrange: Después del trabajo estudio español',
            foreignPhrase: 'Después del trabajo estudio español',
            words: ['estudio', 'Después', 'español', 'trabajo', 'del'],
            solution: ['Después', 'del', 'trabajo', 'estudio', 'español'],
          ),
          _choice(
            id: 'es-4-3',
            prompt: 'Which one means "to sleep"?',
            options: [
              const ChoiceOption(label: 'comer', emoji: '🍽️'),
              const ChoiceOption(label: 'dormir', emoji: '😴'),
              const ChoiceOption(label: 'correr', emoji: '🏃'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'es-5', title: 'Familia', description: 'Family members.',
        status: LessonStatus.locked, orderIndex: 5, languageCode: 'es',
        exercises: [
          _choice(
            id: 'es-5-1',
            prompt: 'Which one of these is "mother"?',
            options: [
              const ChoiceOption(label: 'padre', emoji: '👨'),
              const ChoiceOption(label: 'madre', emoji: '👩'),
              const ChoiceOption(label: 'hermano', emoji: '👦'),
              const ChoiceOption(label: 'hermana', emoji: '👧'),
            ],
            correctIndex: 1,
          ),
          _translate(
            id: 'es-5-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Tengo dos hermanos',
            wordBank: ['I', 'brothers', 'two', 'have', 'three', 'sisters'],
            solution: ['I', 'have', 'two', 'brothers'],
          ),
          _arrange(
            id: 'es-5-3',
            prompt: 'Arrange: Mi familia es grande',
            foreignPhrase: 'Mi familia es grande',
            words: ['grande', 'familia', 'es', 'Mi'],
            solution: ['Mi', 'familia', 'es', 'grande'],
          ),
        ],
      ),
      Lesson(
        id: 'es-6', title: 'Dar Opinión', description: 'Express your opinions.',
        status: LessonStatus.locked, orderIndex: 6, languageCode: 'es',
        exercises: [
          _translate(
            id: 'es-6-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Creo que esta ciudad es bonita',
            wordBank: ['I', 'city', 'is', 'this', 'beautiful', 'think', 'ugly'],
            solution: ['I', 'think', 'this', 'city', 'is', 'beautiful'],
          ),
          _arrange(
            id: 'es-6-2',
            prompt: 'Arrange: En mi opinión es mejor practicar',
            foreignPhrase: 'En mi opinión es mejor practicar',
            words: ['mejor', 'opinión', 'practicar', 'mi', 'En', 'es'],
            solution: ['En', 'mi', 'opinión', 'es', 'mejor', 'practicar'],
          ),
        ],
      ),
    ],

    // ═══════════════  FRENCH  ═══════════════
    'fr': [
      Lesson(
        id: 'fr-1', title: 'Salutations', description: 'French greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'fr',
        exercises: [
          _translate(
            id: 'fr-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Bonjour, comment ça va?',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'they'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'fr-1-2',
            prompt: 'Which one of these is "goodbye"?',
            options: [
              const ChoiceOption(label: 'bonjour', emoji: '👋'),
              const ChoiceOption(label: 'au revoir', emoji: '🚪'),
              const ChoiceOption(label: 'merci', emoji: '🙏'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'fr-1-3',
            prompt: 'Arrange: Bon matin à tous',
            foreignPhrase: 'Bon matin à tous',
            words: ['à', 'tous', 'Bon', 'matin'],
            solution: ['Bon', 'matin', 'à', 'tous'],
          ),
        ],
      ),
      Lesson(
        id: 'fr-2', title: 'Se Présenter', description: 'Introduce yourself in French.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'fr',
        exercises: [
          _translate(
            id: 'fr-2-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Je m\'appelle Ana',
            wordBank: ['name', 'My', 'Ana', 'is', 'has', 'her'],
            solution: ['My', 'name', 'is', 'Ana'],
          ),
          _choice(
            id: 'fr-2-2',
            prompt: 'Which one means "nice to meet you"?',
            options: [
              const ChoiceOption(label: 'enchanté', emoji: '🤝'),
              const ChoiceOption(label: 'au revoir', emoji: '🚪'),
              const ChoiceOption(label: 'comment', emoji: '❓'),
            ],
            correctIndex: 0,
          ),
          _arrange(
            id: 'fr-2-3',
            prompt: 'Arrange: Ravi de te rencontrer',
            foreignPhrase: 'Ravi de te rencontrer',
            words: ['te', 'de', 'rencontrer', 'Ravi'],
            solution: ['Ravi', 'de', 'te', 'rencontrer'],
          ),
        ],
      ),
      Lesson(
        id: 'fr-3', title: 'Nourriture', description: 'Food and drink vocabulary.',
        status: LessonStatus.locked, orderIndex: 3, languageCode: 'fr',
        exercises: [
          _choice(
            id: 'fr-3-1',
            prompt: 'Which one of these is "tea"?',
            options: [
              const ChoiceOption(label: 'un café', emoji: '☕'),
              const ChoiceOption(label: 'un croissant', emoji: '🥐'),
              const ChoiceOption(label: 'un thé', emoji: '🍵'),
            ],
            correctIndex: 2,
          ),
          _translate(
            id: 'fr-3-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Je voudrais un café s\'il vous plaît',
            wordBank: ['would', 'like', 'I', 'a', 'coffee', 'please', 'tea'],
            solution: ['I', 'would', 'like', 'a', 'coffee', 'please'],
          ),
          _choice(
            id: 'fr-3-3',
            prompt: 'Which one of these is "bread"?',
            options: [
              const ChoiceOption(label: 'fromage', emoji: '🧀'),
              const ChoiceOption(label: 'pain', emoji: '🍞'),
              const ChoiceOption(label: 'lait', emoji: '🥛'),
              const ChoiceOption(label: 'oeuf', emoji: '🥚'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'fr-4', title: 'Routine Quotidienne', description: 'Daily routine.',
        status: LessonStatus.locked, orderIndex: 4, languageCode: 'fr',
        exercises: [
          _translate(
            id: 'fr-4-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Je me lève à sept heures',
            wordBank: ['I', 'up', 'get', 'seven', 'at', 'eight', 'sleep'],
            solution: ['I', 'get', 'up', 'at', 'seven'],
          ),
          _arrange(
            id: 'fr-4-2',
            prompt: 'Arrange: Après le travail j\'étudie',
            foreignPhrase: 'Après le travail j\'étudie',
            words: ['j\'étudie', 'travail', 'le', 'Après'],
            solution: ['Après', 'le', 'travail', 'j\'étudie'],
          ),
          _choice(
            id: 'fr-4-3',
            prompt: 'Which one means "to eat"?',
            options: [
              const ChoiceOption(label: 'dormir', emoji: '😴'),
              const ChoiceOption(label: 'manger', emoji: '🍽️'),
              const ChoiceOption(label: 'courir', emoji: '🏃'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'fr-5', title: 'La Famille', description: 'Family members.',
        status: LessonStatus.locked, orderIndex: 5, languageCode: 'fr',
        exercises: [
          _choice(
            id: 'fr-5-1',
            prompt: 'Which one of these is "father"?',
            options: [
              const ChoiceOption(label: 'père', emoji: '👨'),
              const ChoiceOption(label: 'mère', emoji: '👩'),
              const ChoiceOption(label: 'frère', emoji: '👦'),
              const ChoiceOption(label: 'soeur', emoji: '👧'),
            ],
            correctIndex: 0,
          ),
          _translate(
            id: 'fr-5-2',
            prompt: 'Write this in English',
            foreignPhrase: 'J\'ai une grande famille',
            wordBank: ['I', 'a', 'big', 'have', 'family', 'small', 'house'],
            solution: ['I', 'have', 'a', 'big', 'family'],
          ),
        ],
      ),
      Lesson(
        id: 'fr-6', title: 'Donner Son Avis', description: 'Express opinions.',
        status: LessonStatus.locked, orderIndex: 6, languageCode: 'fr',
        exercises: [
          _translate(
            id: 'fr-6-1',
            prompt: 'Write this in English',
            foreignPhrase: 'À mon avis c\'est très bon',
            wordBank: ['In', 'opinion', 'my', 'is', 'very', 'it', 'good', 'bad'],
            solution: ['In', 'my', 'opinion', 'it', 'is', 'very', 'good'],
          ),
          _arrange(
            id: 'fr-6-2',
            prompt: 'Arrange: Je pense que c\'est facile',
            foreignPhrase: 'Je pense que c\'est facile',
            words: ['facile', 'pense', 'que', 'c\'est', 'Je'],
            solution: ['Je', 'pense', 'que', 'c\'est', 'facile'],
          ),
        ],
      ),
    ],

    // ═══════════════  GERMAN  ═══════════════
    'de': [
      Lesson(
        id: 'de-1', title: 'Begrüßung', description: 'German greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'de',
        exercises: [
          _translate(
            id: 'de-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Hallo, wie geht es dir?',
            wordBank: ['Hello,', 'how', 'are', 'you', 'is', 'we'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'de-1-2',
            prompt: 'Which one of these is "good morning"?',
            options: [
              const ChoiceOption(label: 'Guten Morgen', emoji: '🌅'),
              const ChoiceOption(label: 'Gute Nacht', emoji: '🌙'),
              const ChoiceOption(label: 'Tschüss', emoji: '👋'),
            ],
            correctIndex: 0,
          ),
          _arrange(
            id: 'de-1-3',
            prompt: 'Arrange: Guten Morgen zusammen',
            foreignPhrase: 'Guten Morgen zusammen',
            words: ['Morgen', 'zusammen', 'Guten'],
            solution: ['Guten', 'Morgen', 'zusammen'],
          ),
        ],
      ),
      Lesson(
        id: 'de-2', title: 'Sich Vorstellen', description: 'Introduce yourself.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'de',
        exercises: [
          _translate(
            id: 'de-2-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Ich heiße Ana',
            wordBank: ['name', 'My', 'Ana', 'is', 'has', 'their'],
            solution: ['My', 'name', 'is', 'Ana'],
          ),
          _arrange(
            id: 'de-2-2',
            prompt: 'Arrange: Freut mich dich kennenzulernen',
            foreignPhrase: 'Freut mich dich kennenzulernen',
            words: ['dich', 'mich', 'Freut', 'kennenzulernen'],
            solution: ['Freut', 'mich', 'dich', 'kennenzulernen'],
          ),
          _choice(
            id: 'de-2-3',
            prompt: 'Which one means "my name is"?',
            options: [
              const ChoiceOption(label: 'Ich heiße', emoji: '📛'),
              const ChoiceOption(label: 'Ich habe', emoji: '🤲'),
              const ChoiceOption(label: 'Ich bin', emoji: '👤'),
            ],
            correctIndex: 0,
          ),
        ],
      ),
      Lesson(
        id: 'de-3', title: 'Essen und Trinken', description: 'Food and drink.',
        status: LessonStatus.locked, orderIndex: 3, languageCode: 'de',
        exercises: [
          _choice(
            id: 'de-3-1',
            prompt: 'Which one of these is "milk"?',
            options: [
              const ChoiceOption(label: 'Kaffee', emoji: '☕'),
              const ChoiceOption(label: 'Milch', emoji: '🥛'),
              const ChoiceOption(label: 'Wasser', emoji: '💧'),
              const ChoiceOption(label: 'Bier', emoji: '🍺'),
            ],
            correctIndex: 1,
          ),
          _translate(
            id: 'de-3-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Ich möchte einen Kaffee bitte',
            wordBank: ['I', 'a', 'would', 'coffee', 'like', 'please', 'tea'],
            solution: ['I', 'would', 'like', 'a', 'coffee', 'please'],
          ),
          _arrange(
            id: 'de-3-3',
            prompt: 'Arrange: Normalerweise trinke ich Kaffee',
            foreignPhrase: 'Normalerweise trinke ich Kaffee',
            words: ['ich', 'Normalerweise', 'Kaffee', 'trinke'],
            solution: ['Normalerweise', 'trinke', 'ich', 'Kaffee'],
          ),
        ],
      ),
      Lesson(
        id: 'de-4', title: 'Tägliche Routine', description: 'Daily routine.',
        status: LessonStatus.locked, orderIndex: 4, languageCode: 'de',
        exercises: [
          _translate(
            id: 'de-4-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Ich stehe um sieben Uhr auf',
            wordBank: ['I', 'up', 'get', 'seven', 'at', 'eight', 'go'],
            solution: ['I', 'get', 'up', 'at', 'seven'],
          ),
          _choice(
            id: 'de-4-2',
            prompt: 'Which one means "to work"?',
            options: [
              const ChoiceOption(label: 'schlafen', emoji: '😴'),
              const ChoiceOption(label: 'arbeiten', emoji: '💼'),
              const ChoiceOption(label: 'lesen', emoji: '📖'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'de-4-3',
            prompt: 'Arrange: Nach der Arbeit lerne ich Deutsch',
            foreignPhrase: 'Nach der Arbeit lerne ich Deutsch',
            words: ['der', 'ich', 'Arbeit', 'Deutsch', 'lerne', 'Nach'],
            solution: ['Nach', 'der', 'Arbeit', 'lerne', 'ich', 'Deutsch'],
          ),
        ],
      ),
      Lesson(
        id: 'de-5', title: 'Familie', description: 'Family members.',
        status: LessonStatus.locked, orderIndex: 5, languageCode: 'de',
        exercises: [
          _choice(
            id: 'de-5-1',
            prompt: 'Which one of these is "sister"?',
            options: [
              const ChoiceOption(label: 'Vater', emoji: '👨'),
              const ChoiceOption(label: 'Mutter', emoji: '👩'),
              const ChoiceOption(label: 'Bruder', emoji: '👦'),
              const ChoiceOption(label: 'Schwester', emoji: '👧'),
            ],
            correctIndex: 3,
          ),
          _translate(
            id: 'de-5-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Ich habe zwei Brüder',
            wordBank: ['I', 'brothers', 'two', 'have', 'three', 'sisters'],
            solution: ['I', 'have', 'two', 'brothers'],
          ),
        ],
      ),
      Lesson(
        id: 'de-6', title: 'Meinung Äußern', description: 'Express opinions.',
        status: LessonStatus.locked, orderIndex: 6, languageCode: 'de',
        exercises: [
          _translate(
            id: 'de-6-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Ich denke, das ist sehr gut',
            wordBank: ['I', 'think', 'is', 'this', 'very', 'good', 'bad'],
            solution: ['I', 'think', 'this', 'is', 'very', 'good'],
          ),
          _arrange(
            id: 'de-6-2',
            prompt: 'Arrange: Meiner Meinung nach ist es toll',
            foreignPhrase: 'Meiner Meinung nach ist es toll',
            words: ['nach', 'toll', 'Meinung', 'es', 'ist', 'Meiner'],
            solution: ['Meiner', 'Meinung', 'nach', 'ist', 'es', 'toll'],
          ),
        ],
      ),
    ],

    // ═══════════════  ITALIAN  ═══════════════
    'it': [
      Lesson(
        id: 'it-1', title: 'Saluti', description: 'Italian greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'it',
        exercises: [
          _translate(
            id: 'it-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Ciao, come stai?',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'they'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'it-1-2',
            prompt: 'Which one of these is "thank you"?',
            options: [
              const ChoiceOption(label: 'ciao', emoji: '👋'),
              const ChoiceOption(label: 'grazie', emoji: '🙏'),
              const ChoiceOption(label: 'scusa', emoji: '😅'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'it-1-3',
            prompt: 'Arrange: Buongiorno a tutti',
            foreignPhrase: 'Buongiorno a tutti',
            words: ['Buongiorno', 'tutti', 'a'],
            solution: ['Buongiorno', 'a', 'tutti'],
          ),
        ],
      ),
      Lesson(
        id: 'it-2', title: 'Presentarsi', description: 'Introduce yourself.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'it',
        exercises: [
          _translate(
            id: 'it-2-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Mi chiamo Ana',
            wordBank: ['name', 'My', 'Ana', 'is', 'has', 'your'],
            solution: ['My', 'name', 'is', 'Ana'],
          ),
          _arrange(
            id: 'it-2-2',
            prompt: 'Arrange: Piacere di conoscerti',
            foreignPhrase: 'Piacere di conoscerti',
            words: ['conoscerti', 'Piacere', 'di'],
            solution: ['Piacere', 'di', 'conoscerti'],
          ),
        ],
      ),
      Lesson(
        id: 'it-3', title: 'Cibo e Bevande', description: 'Food and drink.',
        status: LessonStatus.locked, orderIndex: 3, languageCode: 'it',
        exercises: [
          _choice(
            id: 'it-3-1',
            prompt: 'Which one of these is "coffee"?',
            options: [
              const ChoiceOption(label: 'un caffè', emoji: '☕'),
              const ChoiceOption(label: 'un cornetto', emoji: '🥐'),
              const ChoiceOption(label: 'un tè', emoji: '🍵'),
            ],
            correctIndex: 0,
          ),
          _translate(
            id: 'it-3-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Vorrei un caffè per favore',
            wordBank: ['would', 'like', 'I', 'a', 'coffee', 'please', 'tea'],
            solution: ['I', 'would', 'like', 'a', 'coffee', 'please'],
          ),
          _arrange(
            id: 'it-3-3',
            prompt: 'Arrange: Di solito bevo caffè al mattino',
            foreignPhrase: 'Di solito bevo caffè al mattino',
            words: ['mattino', 'bevo', 'solito', 'al', 'caffè', 'Di'],
            solution: ['Di', 'solito', 'bevo', 'caffè', 'al', 'mattino'],
          ),
        ],
      ),
      Lesson(
        id: 'it-4', title: 'Routine Quotidiana', description: 'Daily routine.',
        status: LessonStatus.locked, orderIndex: 4, languageCode: 'it',
        exercises: [
          _translate(
            id: 'it-4-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Mi sveglio alle sette',
            wordBank: ['I', 'up', 'wake', 'seven', 'at', 'eight', 'sleep'],
            solution: ['I', 'wake', 'up', 'at', 'seven'],
          ),
          _choice(
            id: 'it-4-2',
            prompt: 'Which one means "to study"?',
            options: [
              const ChoiceOption(label: 'dormire', emoji: '😴'),
              const ChoiceOption(label: 'studiare', emoji: '📚'),
              const ChoiceOption(label: 'mangiare', emoji: '🍽️'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'it-5', title: 'La Famiglia', description: 'Family members.',
        status: LessonStatus.locked, orderIndex: 5, languageCode: 'it',
        exercises: [
          _choice(
            id: 'it-5-1',
            prompt: 'Which one of these is "brother"?',
            options: [
              const ChoiceOption(label: 'padre', emoji: '👨'),
              const ChoiceOption(label: 'madre', emoji: '👩'),
              const ChoiceOption(label: 'fratello', emoji: '👦'),
              const ChoiceOption(label: 'sorella', emoji: '👧'),
            ],
            correctIndex: 2,
          ),
          _translate(
            id: 'it-5-2',
            prompt: 'Write this in English',
            foreignPhrase: 'Ho una sorella e un fratello',
            wordBank: ['I', 'a', 'sister', 'have', 'and', 'brother', 'two'],
            solution: ['I', 'have', 'a', 'sister', 'and', 'a', 'brother'],
          ),
        ],
      ),
    ],

    // ═══════════════  ENGLISH (for non-native speakers) ═══════════════
    'en': [
      Lesson(
        id: 'en-1', title: 'Greetings', description: 'Basic English greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'en',
        exercises: [
          _arrange(
            id: 'en-1-1',
            prompt: 'Arrange: Hello, how are you?',
            words: ['are', 'you', 'Hello,', 'how'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'en-1-2',
            prompt: 'Which one means "goodbye"?',
            options: [
              const ChoiceOption(label: 'hello', emoji: '👋'),
              const ChoiceOption(label: 'goodbye', emoji: '🚪'),
              const ChoiceOption(label: 'thanks', emoji: '🙏'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'en-1-3',
            prompt: 'Arrange: Good morning everyone',
            words: ['morning', 'Good', 'everyone'],
            solution: ['Good', 'morning', 'everyone'],
          ),
        ],
      ),
      Lesson(
        id: 'en-2', title: 'Introduce Yourself', description: 'Say your name and origin.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'en',
        exercises: [
          _arrange(
            id: 'en-2-1',
            prompt: 'Arrange: I am Ana from Spain',
            words: ['from', 'Ana', 'I', 'am', 'Spain'],
            solution: ['I', 'am', 'Ana', 'from', 'Spain'],
          ),
          _arrange(
            id: 'en-2-2',
            prompt: 'Arrange: Nice to meet you',
            words: ['you', 'meet', 'Nice', 'to'],
            solution: ['Nice', 'to', 'meet', 'you'],
          ),
        ],
      ),
      Lesson(
        id: 'en-3', title: 'Daily Routine', description: 'Present-tense sentences.',
        status: LessonStatus.locked, orderIndex: 3, languageCode: 'en',
        exercises: [
          _arrange(
            id: 'en-3-1',
            prompt: 'Arrange: I usually drink coffee in the morning',
            words: ['morning', 'usually', 'drink', 'coffee', 'the', 'I', 'in'],
            solution: ['I', 'usually', 'drink', 'coffee', 'in', 'the', 'morning'],
          ),
          _choice(
            id: 'en-3-2',
            prompt: 'Which one means "to eat"?',
            options: [
              const ChoiceOption(label: 'sleep', emoji: '😴'),
              const ChoiceOption(label: 'eat', emoji: '🍽️'),
              const ChoiceOption(label: 'run', emoji: '🏃'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
      Lesson(
        id: 'en-4', title: 'Express Opinion', description: 'Share your views.',
        status: LessonStatus.locked, orderIndex: 4, languageCode: 'en',
        exercises: [
          _arrange(
            id: 'en-4-1',
            prompt: 'Arrange: I think this city is great',
            words: ['is', 'city', 'I', 'think', 'great', 'this'],
            solution: ['I', 'think', 'this', 'city', 'is', 'great'],
          ),
          _arrange(
            id: 'en-4-2',
            prompt: 'Arrange: In my opinion learning is fun',
            words: ['my', 'learning', 'In', 'is', 'fun', 'opinion'],
            solution: ['In', 'my', 'opinion', 'learning', 'is', 'fun'],
          ),
        ],
      ),
    ],

    // ═══════════════  PORTUGUESE  ═══════════════
    'pt': [
      Lesson(
        id: 'pt-1', title: 'Cumprimentos', description: 'Portuguese greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'pt',
        exercises: [
          _translate(
            id: 'pt-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Olá, como você está?',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'they'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'pt-1-2',
            prompt: 'Which one means "thank you"?',
            options: [
              const ChoiceOption(label: 'olá', emoji: '👋'),
              const ChoiceOption(label: 'obrigado', emoji: '🙏'),
              const ChoiceOption(label: 'tchau', emoji: '🚪'),
            ],
            correctIndex: 1,
          ),
          _arrange(
            id: 'pt-1-3',
            prompt: 'Arrange: Bom dia a todos',
            foreignPhrase: 'Bom dia a todos',
            words: ['a', 'Bom', 'todos', 'dia'],
            solution: ['Bom', 'dia', 'a', 'todos'],
          ),
        ],
      ),
      Lesson(
        id: 'pt-2', title: 'Apresentação', description: 'Introduce yourself.',
        status: LessonStatus.locked, orderIndex: 2, languageCode: 'pt',
        exercises: [
          _translate(
            id: 'pt-2-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Meu nome é Ana',
            wordBank: ['name', 'My', 'Ana', 'is', 'has', 'your'],
            solution: ['My', 'name', 'is', 'Ana'],
          ),
          _arrange(
            id: 'pt-2-2',
            prompt: 'Arrange: Prazer em te conhecer',
            foreignPhrase: 'Prazer em te conhecer',
            words: ['conhecer', 'em', 'Prazer', 'te'],
            solution: ['Prazer', 'em', 'te', 'conhecer'],
          ),
        ],
      ),
    ],

    // ═══════════════  JAPANESE  ═══════════════
    'ja': [
      Lesson(
        id: 'ja-1', title: 'あいさつ', description: 'Japanese greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'ja',
        exercises: [
          _translate(
            id: 'ja-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'こんにちは、お元気ですか？',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'we'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'ja-1-2',
            prompt: 'Which one means "good morning"?',
            options: [
              const ChoiceOption(label: 'おはよう', emoji: '🌅'),
              const ChoiceOption(label: 'さようなら', emoji: '🚪'),
              const ChoiceOption(label: 'ありがとう', emoji: '🙏'),
            ],
            correctIndex: 0,
          ),
        ],
      ),
    ],

    // ═══════════════  CHINESE  ═══════════════
    'zh': [
      Lesson(
        id: 'zh-1', title: '问候', description: 'Chinese greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'zh',
        exercises: [
          _translate(
            id: 'zh-1-1',
            prompt: 'Write this in English',
            foreignPhrase: '你好，你好吗？',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'we'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'zh-1-2',
            prompt: 'Which one means "thank you"?',
            options: [
              const ChoiceOption(label: '你好', emoji: '👋'),
              const ChoiceOption(label: '谢谢', emoji: '🙏'),
              const ChoiceOption(label: '再见', emoji: '🚪'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
    ],

    // ═══════════════  RUSSIAN  ═══════════════
    'ru': [
      Lesson(
        id: 'ru-1', title: 'Приветствия', description: 'Russian greetings.',
        status: LessonStatus.locked, orderIndex: 1, languageCode: 'ru',
        exercises: [
          _translate(
            id: 'ru-1-1',
            prompt: 'Write this in English',
            foreignPhrase: 'Привет, как дела?',
            wordBank: ['Hello,', 'how', 'you', 'are', 'is', 'they'],
            solution: ['Hello,', 'how', 'are', 'you'],
          ),
          _choice(
            id: 'ru-1-2',
            prompt: 'Which one means "thank you"?',
            options: [
              const ChoiceOption(label: 'привет', emoji: '👋'),
              const ChoiceOption(label: 'спасибо', emoji: '🙏'),
              const ChoiceOption(label: 'пока', emoji: '🚪'),
            ],
            correctIndex: 1,
          ),
        ],
      ),
    ],
  };
}
