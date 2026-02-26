/// Centralized UI strings for L10n (Clean Architecture).
/// Use [AppStrings.forLocale] with locale code 'en' or 'ro'.
/// Romanian uses UTF-8: ș, ț, ă, î, â.
class AppStrings {
  AppStrings._();

  static AppStringsData forLocale(String localeCode) {
    final isRo = localeCode.toLowerCase().startsWith('ro');
    return isRo ? _roStrings : _enStrings;
  }

  static final AppStringsData _enStrings = AppStringsData(
    welcomeBack: 'Welcome Back',
    welcomeToApp: 'Welcome to\nAI Language Buddy',
    welcomeSubtitle: 'The most immersive language learning app in the world.\nBuilt so you stick with it.',
    emailAddress: 'Email Address',
    email: 'Email',
    getStarted: 'Get Started',
    continueWithEmail: 'Continue with Email',
    continueWithGoogle: 'Continue with Google',
    continueWithApple: 'Continue with Apple',
    or: 'or',
    alreadyHaveAccount: 'Already have an account?',
    logIn: 'Log in',
    signIn: 'Sign in',
    signInWithGoogle: 'Sign in with Google',
    createAccount: 'Create account',
    dontHaveAccount: "Don't have an account? Create one",
    forgotPassword: 'Forgot password?',
    password: 'Password',
    nameOptional: 'Name (optional)',
    yourName: 'Your name',
    youExampleCom: 'you@example.com',
    atLeast6Chars: 'At least 6 characters',
    enterYourEmail: 'Enter your email',
    enterValidEmail: 'Enter a valid email',
    passwordMin6: 'Password must be at least 6 characters',
    invalidEmailOrPassword: 'Invalid email or password.',
    confirmEmailFirst: 'Please confirm your email first. Check your inbox (and spam) for the confirmation link from Supabase.',
    checkEmailConfirm: 'Check your email to confirm your account',
    accountCreated: 'Account created!',
    appleSignInComing: 'Apple Sign In coming soon!',
    enterEmailResetLink: 'Enter your email and we\'ll send you a link to reset your password.',
    checkYourEmail: 'Check your email',
    weSentLink: 'We sent a password reset link to',
    backToSignIn: 'Back to sign in',
    sendResetLink: 'Send reset link',
    goodMorning: 'Good morning',
    readyToLearn: 'ready to learn?',
    practice: 'Practice',
    currentLesson: 'Current Lesson',
    wordsLearned: 'Words Learned',
    allTopics: 'All topics',
    custom: 'Custom',
    wordOfTheDay: 'word of the day',
    checkTodays: "Check today's",
    upgrade: 'Upgrade',
    errorLoadingTopics: 'Error loading topics',
    errorLoadingCustomTopics: 'Error loading custom topics',
    addTopic: 'Add topic',
    noCustomTopicsYet: 'No custom topics yet',
    createTopic: 'Create a topic',
    startFreeTalk: 'Start free talk',
    noLessonsYet: 'No lessons yet',
    errorLoadingLessons: 'Error loading lessons',
    retry: 'Retry',
    noInteractiveContent: 'No interactive content found.',
    backToHome: 'Back to home',
    lessons: 'Lessons',
    lessonsAndTracks: 'Lessons & tracks',
    personalizedLessons: 'Personalized lessons from your mistakes.',
    comingSoon: 'Coming soon',
    comingSoonDescription: 'We\'ll generate bite-sized lessons and review tracks from your chat history.',
    happy: 'Happy',
    sad: 'Sad',
    tired: 'Tired',
    continueButton: 'Continue',
    challenge: 'Challenge',
    progress: 'Progress',
    lessonCompleted: 'Lesson Completed!',
    lessonCompletedAndSaved: 'Lesson completed and progress saved!',
    saving: 'Saving...',
    profile: 'Profile',
    targetLanguage: 'Target Language',
    darkMode: 'Dark Mode',
    darkTheme: 'Dark Theme',
    accountDetails: 'Account Details',
    account: 'Account',
    settings: 'Settings',
    languagePreferences: 'Language Preferences',
    notifications: 'Notifications',
    signOut: 'Sign Out',
    notLoggedIn: 'Not Logged In',
    noEmail: 'No Email',
    appLanguage: 'App language',
    practiceSession: 'Practice Session',
    startOver: 'Start over',
    conversationCleared: 'Conversation cleared. Starting fresh.',
    typeAMessage: 'Type a message...',
    listening: 'Listening...',
    sarahIsTyping: 'Sarah is typing...',
    sarah: 'Sarah',
    listen: 'Listen',
    feedback: 'Feedback',
    correction: 'Correction',
    tip: 'Tip',
    ok: 'OK',
    error: 'Error',
    liveAssistant: 'Live Assistant',
    reconnectWs: 'Reconnect WS',
    holdToSpeak: 'Hold to Speak',
    tapHoldToSpeak: 'Tap & Hold to Speak',
    liveThinking: 'Thinking...',
    liveSpeaking: 'Speaking...',
    selectCorrectTranslation: 'Select the correct translation',
    translateThisSentenceLabel: 'Translate this sentence',
    whichOneIsHello: 'Which one is "hello"?',
    howDoYouSayHello: 'How do you say "hello"?',
  );

  static final AppStringsData _roStrings = AppStringsData(
    welcomeBack: 'Bun venit înapoi',
    welcomeToApp: 'Bine ai venit la\nAI Language Buddy',
    welcomeSubtitle: 'Cea mai captivantă aplicație de învățare a limbilor.\nFăcută să te ții de ea.',
    emailAddress: 'Adresă de email',
    email: 'Email',
    getStarted: 'Începe acum',
    continueWithEmail: 'Continuă cu email',
    continueWithGoogle: 'Continuă cu Google',
    continueWithApple: 'Continuă cu Apple',
    or: 'sau',
    alreadyHaveAccount: 'Ai deja cont?',
    logIn: 'Autentificare',
    signIn: 'Autentificare',
    signInWithGoogle: 'Autentificare cu Google',
    createAccount: 'Creează cont',
    dontHaveAccount: 'Nu ai cont? Creează unul',
    forgotPassword: 'Ai uitat parola?',
    password: 'Parolă',
    nameOptional: 'Nume (opțional)',
    yourName: 'Numele tău',
    youExampleCom: 'tu@exemplu.com',
    atLeast6Chars: 'Minim 6 caractere',
    enterYourEmail: 'Introdu adresa de email',
    enterValidEmail: 'Introdu o adresă de email validă',
    passwordMin6: 'Parola trebuie să aibă minim 6 caractere',
    invalidEmailOrPassword: 'Email sau parolă incorectă.',
    confirmEmailFirst: 'Te rugăm să îți confirmi mai întâi emailul. Verifică inbox-ul (și spam) pentru linkul de confirmare de la Supabase.',
    checkEmailConfirm: 'Verifică emailul pentru a-ți confirma contul',
    accountCreated: 'Cont creat!',
    appleSignInComing: 'Autentificarea cu Apple vine în curând!',
    enterEmailResetLink: 'Introdu emailul și îți trimitem un link pentru resetarea parolei.',
    checkYourEmail: 'Verifică emailul',
    weSentLink: 'Ți-am trimis un link de resetare a parolei la',
    backToSignIn: 'Înapoi la autentificare',
    sendResetLink: 'Trimite link de resetare',
    goodMorning: 'Bună dimineața',
    readyToLearn: 'ești gata să înveți?',
    practice: 'Exersare',
    currentLesson: 'Lecția curentă',
    wordsLearned: 'Cuvinte învățate',
    allTopics: 'Toate temele',
    custom: 'Personalizat',
    wordOfTheDay: 'cuvântul zilei',
    checkTodays: 'Vezi',
    upgrade: 'Upgrade',
    errorLoadingTopics: 'Eroare la încărcarea temelor',
    errorLoadingCustomTopics: 'Eroare la încărcarea temelor personalizate',
    addTopic: 'Adaugă temă',
    noCustomTopicsYet: 'Nicio temă personalizată încă',
    createTopic: 'Creează o temă',
    startFreeTalk: 'Începe conversația liberă',
    noLessonsYet: 'Nicio lecție încă',
    errorLoadingLessons: 'Eroare la încărcarea lecțiilor',
    retry: 'Reîncearcă',
    noInteractiveContent: 'Nu s-a găsit conținut interactiv.',
    backToHome: 'Înapoi acasă',
    lessons: 'Lecții',
    lessonsAndTracks: 'Lecții și trasee',
    personalizedLessons: 'Lecții personalizate din greșelile tale.',
    comingSoon: 'În curând',
    comingSoonDescription: 'Vom genera lecții scurte și trasee de recapitulare din istoricul conversațiilor.',
    happy: 'Fericit',
    sad: 'Trist',
    tired: 'Obosit',
    continueButton: 'Continuă',
    challenge: 'Provocare',
    progress: 'Progres',
    lessonCompleted: 'Lecție finalizată!',
    lessonCompletedAndSaved: 'Lecția a fost finalizată și progresul a fost salvat!',
    saving: 'Se salvează...',
    profile: 'Profil',
    targetLanguage: 'Limba țintă',
    darkMode: 'Mod întunecat',
    darkTheme: 'Temă întunecată',
    accountDetails: 'Detalii cont',
    account: 'Cont',
    settings: 'Setări',
    languagePreferences: 'Preferințe limbă',
    notifications: 'Notificări',
    signOut: 'Deconectare',
    notLoggedIn: 'Nu ești autentificat',
    noEmail: 'Fără email',
    appLanguage: 'Limba aplicației',
    practiceSession: 'Sesiune de exersare',
    startOver: 'Începe din nou',
    conversationCleared: 'Conversația a fost ștearsă. Începem din nou.',
    typeAMessage: 'Scrie un mesaj...',
    listening: 'Ascult...',
    sarahIsTyping: 'Sarah scrie...',
    sarah: 'Sarah',
    listen: 'Ascultă',
    feedback: 'Feedback',
    correction: 'Corecție',
    tip: 'Sfat',
    ok: 'OK',
    error: 'Eroare',
    liveAssistant: 'Asistent vocal',
    reconnectWs: 'Reconectează',
    holdToSpeak: 'Ține apăsat pentru a vorbi',
    tapHoldToSpeak: 'Apasă și ține pentru a vorbi',
    liveThinking: 'Se gândește...',
    liveSpeaking: 'Vorbește...',
    selectCorrectTranslation: 'Selectează traducerea corectă',
    translateThisSentenceLabel: 'Tradu această propoziție',
    whichOneIsHello: 'Care variantă este corectă pentru „hello”?',
    howDoYouSayHello: 'Cum spui „hello” corect?',
  );
}

class AppStringsData {
  const AppStringsData({
    required this.welcomeBack,
    required this.welcomeToApp,
    required this.welcomeSubtitle,
    required this.emailAddress,
    required this.email,
    required this.getStarted,
    required this.continueWithEmail,
    required this.continueWithGoogle,
    required this.continueWithApple,
    required this.or,
    required this.alreadyHaveAccount,
    required this.logIn,
    required this.signIn,
    required this.signInWithGoogle,
    required this.createAccount,
    required this.dontHaveAccount,
    required this.forgotPassword,
    required this.password,
    required this.nameOptional,
    required this.yourName,
    required this.youExampleCom,
    required this.atLeast6Chars,
    required this.enterYourEmail,
    required this.enterValidEmail,
    required this.passwordMin6,
    required this.invalidEmailOrPassword,
    required this.confirmEmailFirst,
    required this.checkEmailConfirm,
    required this.accountCreated,
    required this.appleSignInComing,
    required this.enterEmailResetLink,
    required this.checkYourEmail,
    required this.weSentLink,
    required this.backToSignIn,
    required this.sendResetLink,
    required this.goodMorning,
    required this.readyToLearn,
    required this.practice,
    required this.currentLesson,
    required this.wordsLearned,
    required this.allTopics,
    required this.custom,
    required this.wordOfTheDay,
    required this.checkTodays,
    required this.upgrade,
    required this.errorLoadingTopics,
    required this.errorLoadingCustomTopics,
    required this.addTopic,
    required this.noCustomTopicsYet,
    required this.createTopic,
    required this.startFreeTalk,
    required this.noLessonsYet,
    required this.errorLoadingLessons,
    required this.retry,
    required this.noInteractiveContent,
    required this.backToHome,
    required this.lessons,
    required this.lessonsAndTracks,
    required this.personalizedLessons,
    required this.comingSoon,
    required this.comingSoonDescription,
    required this.happy,
    required this.sad,
    required this.tired,
    required this.continueButton,
    required this.challenge,
    required this.progress,
    required this.lessonCompleted,
    required this.lessonCompletedAndSaved,
    required this.saving,
    required this.profile,
    required this.targetLanguage,
    required this.darkMode,
    required this.darkTheme,
    required this.accountDetails,
    required this.account,
    required this.settings,
    required this.languagePreferences,
    required this.notifications,
    required this.signOut,
    required this.notLoggedIn,
    required this.noEmail,
    required this.appLanguage,
    required this.practiceSession,
    required this.startOver,
    required this.conversationCleared,
    required this.typeAMessage,
    required this.listening,
    required this.sarahIsTyping,
    required this.sarah,
    required this.listen,
    required this.feedback,
    required this.correction,
    required this.tip,
    required this.ok,
    required this.error,
    required this.liveAssistant,
    required this.reconnectWs,
    required this.holdToSpeak,
    required this.tapHoldToSpeak,
    required this.liveThinking,
    required this.liveSpeaking,
    required this.selectCorrectTranslation,
    required this.translateThisSentenceLabel,
    required this.whichOneIsHello,
    required this.howDoYouSayHello,
  });

  final String welcomeBack;
  final String welcomeToApp;
  final String welcomeSubtitle;
  final String emailAddress;
  final String email;
  final String getStarted;
  final String continueWithEmail;
  final String continueWithGoogle;
  final String continueWithApple;
  final String or;
  final String alreadyHaveAccount;
  final String logIn;
  final String signIn;
  final String signInWithGoogle;
  final String createAccount;
  final String dontHaveAccount;
  final String forgotPassword;
  final String password;
  final String nameOptional;
  final String yourName;
  final String youExampleCom;
  final String atLeast6Chars;
  final String enterYourEmail;
  final String enterValidEmail;
  final String passwordMin6;
  final String invalidEmailOrPassword;
  final String confirmEmailFirst;
  final String checkEmailConfirm;
  final String accountCreated;
  final String appleSignInComing;
  final String enterEmailResetLink;
  final String checkYourEmail;
  final String weSentLink;
  final String backToSignIn;
  final String sendResetLink;
  final String goodMorning;
  final String readyToLearn;
  final String practice;
  final String currentLesson;
  final String wordsLearned;
  final String allTopics;
  final String custom;
  final String wordOfTheDay;
  final String checkTodays;
  final String upgrade;
  final String errorLoadingTopics;
  final String errorLoadingCustomTopics;
  final String addTopic;
  final String noCustomTopicsYet;
  final String createTopic;
  final String startFreeTalk;
  final String noLessonsYet;
  final String errorLoadingLessons;
  final String retry;
  final String noInteractiveContent;
  final String backToHome;
  final String lessons;
  final String lessonsAndTracks;
  final String personalizedLessons;
  final String comingSoon;
  final String comingSoonDescription;
  final String happy;
  final String sad;
  final String tired;
  final String continueButton;
  final String challenge;
  final String progress;
  final String lessonCompleted;
  final String lessonCompletedAndSaved;
  final String saving;
  final String profile;
  final String targetLanguage;
  final String darkMode;
  final String darkTheme;
  final String accountDetails;
  final String account;
  final String settings;
  final String languagePreferences;
  final String notifications;
  final String signOut;
  final String notLoggedIn;
  final String noEmail;
  final String appLanguage;
  final String practiceSession;
  final String startOver;
  final String conversationCleared;
  final String typeAMessage;
  final String listening;
  final String sarahIsTyping;
  final String sarah;
  final String listen;
  final String feedback;
  final String correction;
  final String tip;
  final String ok;
  final String error;
  final String liveAssistant;
  final String reconnectWs;
  final String holdToSpeak;
  final String tapHoldToSpeak;
  final String liveThinking;
  final String liveSpeaking;
  final String selectCorrectTranslation;
  final String translateThisSentenceLabel;
  final String whichOneIsHello;
  final String howDoYouSayHello;
}
