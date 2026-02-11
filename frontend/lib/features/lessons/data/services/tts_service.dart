import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';

/// Provides word-level TTS for the lesson UI.
/// Calls the voice service `/synthesize/word` endpoint and caches results
/// in memory so repeated taps are instant.
class LessonTtsService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final Map<String, Uint8List> _cache = {};
  bool _isPlayerOpen = false;
  bool _isPlaying = false;

  /// Play a word/phrase in the given language.
  Future<void> speak(String text, String languageCode) async {
    if (_isPlaying) return; // Debounce rapid taps
    _isPlaying = true;

    try {
      if (!_isPlayerOpen) {
        await _player.openPlayer();
        _isPlayerOpen = true;
      }

      final key = '$languageCode:${text.toLowerCase().trim()}';
      Uint8List audioBytes;

      if (_cache.containsKey(key)) {
        audioBytes = _cache[key]!;
      } else {
        final url = ApiRoutes.synthesizeWord(text: text, lang: languageCode);
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode != 200) {
          throw Exception('TTS failed: ${response.statusCode}');
        }
        audioBytes = response.bodyBytes;
        _cache[key] = audioBytes;
      }

      await _player.startPlayer(
        fromDataBuffer: audioBytes,
        sampleRate: 24000,
        codec: Codec.pcm16,
        whenFinished: () {
          _isPlaying = false;
        },
      );
    } catch (e) {
      _isPlaying = false;
      // Silently fail — TTS is nice-to-have, don't block the user
    }
  }

  Future<void> dispose() async {
    if (_isPlayerOpen) {
      await _player.closePlayer();
      _isPlayerOpen = false;
    }
    _cache.clear();
  }
}

final lessonTtsServiceProvider = Provider<LessonTtsService>((ref) {
  final service = LessonTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});
