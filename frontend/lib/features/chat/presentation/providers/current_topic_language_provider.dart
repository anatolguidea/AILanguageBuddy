import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language code (en, ro, fr, etc.) for the currently open chat topic.
/// Set when user taps a topic; used for API and TTS so voice matches the conversation.
final currentTopicLanguageProvider = StateProvider<String?>((ref) => null);
