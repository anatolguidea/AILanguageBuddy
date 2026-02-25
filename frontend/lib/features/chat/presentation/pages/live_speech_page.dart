import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../providers/chat_provider.dart';
import 'package:ailanguageapp/core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/language_provider.dart';

// Helper to convert HTTP URL to WS URL
String _getWsUrl(String? userId, String? accessToken, String? targetLanguageCode) {
  final uri = Uri.parse(kBaseUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final host = uri.host;
  final port = uri.port;
  String url = '$scheme://$host:$port/ws/voice';
  final query = <String>[];
  if (userId != null && userId.isNotEmpty) {
    query.add('userId=$userId');
  }
  if (accessToken != null && accessToken.isNotEmpty) {
    query.add('token=$accessToken');
  }
  if (targetLanguageCode != null && targetLanguageCode.isNotEmpty) {
    query.add('targetLanguage=${Uri.encodeComponent(targetLanguageCode)}');
  }
  if (query.isNotEmpty) {
    url += '?${query.join('&')}';
  }
  return url;
}

String _normalizeLangCode(String raw) {
  final v = raw.trim().toLowerCase();
  if (v == 'e' || v.isEmpty) return 'en';
  if (v == 'f') return 'fr';
  if (v.length >= 2) return v.split('-').first;
  return 'en';
}

final liveSpeechProvider = StateNotifierProvider<LiveSpeechNotifier, LiveSpeechState>((ref) {
  return LiveSpeechNotifier(ref);
});

/// Voice uses the language selected on the lesson screen (language list). When user switches
/// language there, we reconnect so LLM and TTS use the new language.
final voiceTargetLanguageCodeProvider = Provider<String>((ref) {
  final lang = ref.watch(languageProvider);
  return _normalizeLangCode(lang.code ?? 'en');
});

/// When mounted (e.g. in shell), listens to language changes and reconnects voice WS so
/// switching language on the lesson screen immediately applies to voice.
final voiceReconnectOnLanguageChangeProvider = Provider<void>((ref) {
  final notifier = ref.watch(liveSpeechProvider.notifier);
  ref.listen(voiceTargetLanguageCodeProvider, (prev, next) {
    if (next.isEmpty) return;
    if (prev != null && prev != next) {
      notifier.disconnect();
      notifier.connect(targetLanguageCode: next);
    }
  });
});

enum VoiceState { idle, listening, processing, speaking, error }

class LiveSpeechState {
  final VoiceState status;
  final String? errorMessage;
  final String lastTranscript;

  LiveSpeechState({
    this.status = VoiceState.idle,
    this.errorMessage,
    this.lastTranscript = '',
  });

  LiveSpeechState copyWith({
    VoiceState? status,
    String? errorMessage,
    String? lastTranscript,
  }) {
    return LiveSpeechState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastTranscript: lastTranscript ?? this.lastTranscript,
    );
  }
}

class LiveSpeechNotifier extends StateNotifier<LiveSpeechState> {
  final Ref _ref;
  WebSocketChannel? _channel;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _recorderSubscription;
  String _lastAudioCodec = 'pcm16';
  int _lastAudioSampleRate = 24000;

  LiveSpeechNotifier(this._ref) : super(LiveSpeechState()) {
    _init();
  }

  Future<void> _init() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    
    // Configure Audio Session for Speech
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth | AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  /// Connect to voice WebSocket. Uses [targetLanguageCode] from profile when not provided.
  Future<void> connect({String? targetLanguageCode}) async {
    try {
      _disconnectChannel(); // close existing if any
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final raw = targetLanguageCode ?? _ref.read(languageProvider).code;
      final langCode = _normalizeLangCode(raw);
      final url = _getWsUrl(userId, accessToken, langCode);
      print('Attempting to connect to WS: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready; // Wait for connection to be established
      print('WebSocket Connection Established');
      state = state.copyWith(status: VoiceState.idle, errorMessage: null);

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            print('WS Text: $message');
            if (message.startsWith('AUDIO:')) {
              final rest = message.substring(6);
              final parts = rest.split(',');
              if (parts.length >= 2) {
                _lastAudioCodec = parts[0].trim().toLowerCase();
                _lastAudioSampleRate = int.tryParse(parts[1].trim()) ?? 24000;
              }
            }
          } else {
            print('WS Binary: ${message.runtimeType} length: ${(message as List).length}');
            _playAudio(message);
          }
        },
        onError: (error) {
          print('WS Error callback: $error');
          state = state.copyWith(status: VoiceState.error, errorMessage: "WS Error: $error");
        },
        onDone: () {
          print('WS Closed');
          state = state.copyWith(status: VoiceState.idle, errorMessage: "Disconnected");
        },
      );
    } catch (e) {
      print('WS Connection Exception: $e');
      state = state.copyWith(status: VoiceState.error, errorMessage: "Conn Error: $e");
    }
  }

  /// Disconnect and clear channel. Call before reconnect with new language.
  void disconnect() {
    _disconnectChannel();
    state = state.copyWith(status: VoiceState.idle, errorMessage: null);
  }

  void _disconnectChannel() {
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      state = state.copyWith(status: VoiceState.error, errorMessage: "Mic permission permanently denied. Open Settings.");
      await openAppSettings();
      return;
    }

    if (!status.isGranted) {
       state = state.copyWith(status: VoiceState.error, errorMessage: "Mic permission denied");
       return;
    }

    if (_channel == null) await connect();

    state = state.copyWith(status: VoiceState.listening);

    // Create a StreamController to receive audio from recorder and forward to WS
    final recordingDataController = StreamController<Uint8List>();
    _recorderSubscription = recordingDataController.stream.listen((buffer) {
      if (_channel != null) {
        _channel!.sink.add(buffer);
      }
    });

    await _recorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000, 
    );
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    if (_recorderSubscription != null) {
      await _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
    
    // Send End-Of-Speech signal
    if (_channel != null) {
      print("Sending EOS signal");
      _channel!.sink.add("EOS");
    }
    
    state = state.copyWith(status: VoiceState.processing);
  }

  Future<void> _playAudio(dynamic data) async {
    state = state.copyWith(status: VoiceState.speaking);
    final Uint8List bytes = data is Uint8List ? data : Uint8List.fromList(List<int>.from(data));
    final codec = _lastAudioCodec == 'mp3' ? Codec.mp3 : Codec.pcm16;
    await _player!.startPlayer(
      fromDataBuffer: bytes,
      sampleRate: _lastAudioSampleRate,
      codec: codec,
      whenFinished: () {
        state = state.copyWith(status: VoiceState.idle);
      },
    );
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _disconnectChannel();
    super.dispose();
  }
}

void _showAppLanguagePicker(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(appLocaleProvider.notifier);
  final current = ref.read(appLocaleProvider);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                current == AppLocaleNotifier.en ? Icons.check_circle : Icons.circle_outlined,
                color: current == AppLocaleNotifier.en ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                size: 22,
              ),
              title: const Text('English'),
              onTap: () {
                notifier.setLocale(AppLocaleNotifier.en);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                current == AppLocaleNotifier.ro ? Icons.check_circle : Icons.circle_outlined,
                color: current == AppLocaleNotifier.ro ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                size: 22,
              ),
              title: const Text('Română'),
              onTap: () {
                notifier.setLocale(AppLocaleNotifier.ro);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class LiveSpeechPage extends ConsumerWidget {
  const LiveSpeechPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(liveSpeechProvider);
    final notifier = ref.read(liveSpeechProvider.notifier);
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final scheme = Theme.of(context).colorScheme;

    // When effective language changes (or on first open), connect/reconnect with current target language
    ref.listen(voiceTargetLanguageCodeProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      if (prev == null) {
        // First time opening voice screen: connect with current language (e.g. from lecon topic)
        notifier.connect(targetLanguageCode: next);
      } else if (prev != next) {
        // User changed language (e.g. switched topic on lecon then came back): reconnect
        notifier.disconnect();
        notifier.connect(targetLanguageCode: next);
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(s.liveAssistant),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.language_rounded, color: scheme.onSurface),
            onPressed: () => _showAppLanguagePicker(context, ref),
            tooltip: s.appLanguage,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (speechState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  speechState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error, fontSize: 14),
                ),
              ),
            GestureDetector(
              onLongPressStart: (_) => notifier.startRecording(),
              onLongPressEnd: (_) => notifier.stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColor(speechState.status, scheme),
                  boxShadow: [
                    if (speechState.status == VoiceState.listening)
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      )
                  ],
                ),
                child: Icon(
                  _getIcon(speechState.status),
                  size: 80,
                  color: _getIconColor(speechState.status, scheme),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _getStatusText(speechState.status, s),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.holdToSpeak,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(VoiceState status, ColorScheme scheme) {
    switch (status) {
      case VoiceState.listening:
        return scheme.primary;
      case VoiceState.processing:
        return AppColors.secondary;
      case VoiceState.speaking:
        return Colors.green;
      case VoiceState.error:
        return scheme.error;
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  IconData _getIcon(VoiceState status) {
    switch (status) {
      case VoiceState.listening:
        return FontAwesomeIcons.microphoneLines;
      case VoiceState.processing:
        return FontAwesomeIcons.brain;
      case VoiceState.speaking:
        return FontAwesomeIcons.volumeHigh;
      default:
        return FontAwesomeIcons.microphone;
    }
  }

  Color _getIconColor(VoiceState status, ColorScheme scheme) {
    switch (status) {
      case VoiceState.listening:
        return scheme.onPrimary;
      case VoiceState.processing:
        return scheme.onSecondary;
      case VoiceState.speaking:
        return Colors.white;
      case VoiceState.error:
        return scheme.onError;
      default:
        return scheme.onSurface;
    }
  }

  String _getStatusText(VoiceState status, AppStringsData s) {
    switch (status) {
      case VoiceState.listening:
        return s.listening;
      case VoiceState.processing:
        return s.liveThinking;
      case VoiceState.speaking:
        return s.liveSpeaking;
      default:
        return s.tapHoldToSpeak;
    }
  }
}
