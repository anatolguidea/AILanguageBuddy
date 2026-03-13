import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../../data/chat_repository.dart';
import '../../presentation/providers/current_topic_language_provider.dart';

final chatAudioServiceProvider = Provider<ChatAudioService>((ref) {
  return ChatAudioService(
    repository: ref.watch(chatRepositoryProvider),
    ref: ref,
  );
});

class ChatAudioService {
  ChatAudioService({
    required ChatRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref;

  final ChatRepository _repository;
  final Ref _ref;

  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  FlutterSoundPlayer? _backendTtsPlayer;
  bool _backendPlayerOpened = false;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(bool isSpeaking) onSpeakingChanged,
    required void Function(String message) onError,
  }) async {
    if (_initialized) {
      return;
    }
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      onSpeakingChanged(true);
    });
    _flutterTts.setCompletionHandler(() {
      onSpeakingChanged(false);
    });
    _flutterTts.setErrorHandler((msg) {
      onSpeakingChanged(false);
      onError('TTS Error: $msg');
    });
    _initialized = true;
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function(bool isListening) onListeningChanged,
    required void Function(String message) onError,
  }) async {
    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            onListeningChanged(false);
          }
        },
        onError: (errorNotification) {
          onListeningChanged(false);
          onError('STT Error: ${errorNotification.errorMsg}');
        },
      );
      if (!available) {
        onError('Speech recognition not available');
        return;
      }
      onListeningChanged(true);
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );
    } catch (e) {
      throw AppFailure(
        message: 'Failed to initialize speech recognition.',
        code: 'stt_init_failed',
        cause: e,
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      throw AppFailure(
        message: 'Failed to stop speech recognition.',
        code: 'stt_stop_failed',
        cause: e,
      );
    }
  }

  Future<void> speak(
    String text, {
    required void Function(bool isSpeaking) onSpeakingChanged,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }
    onSpeakingChanged(true);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      onSpeakingChanged(false);
      throw const AppFailure(
        message: 'Not authenticated.',
        code: 'auth_missing_token',
      );
    }

    final code = _resolveLanguageCode();
    try {
      final audio = await _repository.synthesizeSpeech(
        accessToken: token,
        text: text,
        languageCode: code,
      );
      await _playBackendAudio(audio);
    } on AppFailure {
      await _flutterTts.speak(text);
    } catch (e) {
      onSpeakingChanged(false);
      throw AppFailure(
        message: 'Unable to play speech output.',
        code: 'tts_playback_failed',
        cause: e,
      );
    } finally {
      onSpeakingChanged(false);
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (_backendTtsPlayer != null && _backendTtsPlayer!.isPlaying) {
        await _backendTtsPlayer!.stopPlayer();
      }
    } catch (e) {
      throw AppFailure(
        message: 'Failed to stop speech playback.',
        code: 'tts_stop_failed',
        cause: e,
      );
    }
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
    await _speechToText.stop();
    if (_backendTtsPlayer != null) {
      await _backendTtsPlayer!.closePlayer();
      _backendTtsPlayer = null;
      _backendPlayerOpened = false;
    }
  }

  String _resolveLanguageCode() {
    final currentTopicCode = _ref.read(currentTopicLanguageProvider);
    final fallbackCode = _ref.read(languageProvider).code;
    final lang = (currentTopicCode ?? fallbackCode).trim().toLowerCase();
    if (lang == 'e' || lang.isEmpty) {
      return 'en';
    }
    if (lang == 'f') {
      return 'fr';
    }
    return lang.length >= 2 ? lang.split('-').first : 'en';
  }

  Future<void> _playBackendAudio(ChatSpeechAudio audio) async {
    _backendTtsPlayer ??= FlutterSoundPlayer();
    if (!_backendPlayerOpened) {
      await _backendTtsPlayer!.openPlayer();
      _backendPlayerOpened = true;
    }
    if (_backendTtsPlayer!.isPlaying) {
      await _backendTtsPlayer!.stopPlayer();
    }

    final codec = audio.codec.toLowerCase() == 'mp3' ? Codec.mp3 : Codec.pcm16;
    await _backendTtsPlayer!.startPlayer(
      fromDataBuffer: Uint8List.fromList(audio.bytes),
      codec: codec,
      sampleRate: audio.sampleRate,
    );
  }
}
