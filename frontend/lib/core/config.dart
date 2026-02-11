import 'package:flutter_dotenv/flutter_dotenv.dart';

// Use 127.0.0.1 so iOS Simulator reaches the host Mac. For a physical device, set BACKEND_BASE_URL to your Mac's IP (e.g. http://192.168.1.x:8080).
String get defaultBackendBaseUrl {
  try {
    final fromEnv = dotenv.env['BACKEND_BASE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  } catch (_) {
    // dotenv not loaded or .env missing — use compile-time default
  }
  return const String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
}

/// Supabase project URL and anon key (from .env: SUPABASE_URL, SUPABASE_ANON_KEY).
String get supabaseUrl {
  try {
    final v = dotenv.env['SUPABASE_URL'];
    if (v != null && v.isNotEmpty) return v;
  } catch (_) {}
  return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
}

String get supabaseAnonKey {
  try {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    if (v != null && v.isNotEmpty) return v;
  } catch (_) {}
  return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}

/// Voice service base URL (Python Chatterbox service on port 8000).
String get voiceServiceBaseUrl {
  try {
    final fromEnv = dotenv.env['VOICE_SERVICE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  } catch (_) {}
  return const String.fromEnvironment(
    'VOICE_SERVICE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}

/// API endpoints used across features.
class ApiRoutes {
  static String chatAsk() => '$defaultBackendBaseUrl/api/v1/chat/ask';
  static String chatHistory({int limit = 50}) =>
      '$defaultBackendBaseUrl/api/v1/chat/history/v2?limit=$limit';

  // Voice / TTS
  static String synthesizeWord({required String text, required String lang}) =>
      '$voiceServiceBaseUrl/synthesize/word?text=${Uri.encodeComponent(text)}&lang=${Uri.encodeComponent(lang)}';
}
