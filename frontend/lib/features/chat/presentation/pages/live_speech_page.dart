import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config.dart';
import '../../../../theme/app_colors.dart';
import 'package:ailanguageapp/core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/language_provider.dart';

String get _chatApiBaseUrl => '$defaultBackendBaseUrl/api/v1/chat';

// Helper to convert HTTP URL to WS URL
String _getWsUrl(String? targetLanguageCode) {
  final uri = Uri.parse(_chatApiBaseUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final host = uri.host;
  final port = uri.port;
  String url = '$scheme://$host:$port/ws/voice';
  final query = <String>[];
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

final liveSpeechProvider =
    StateNotifierProvider<LiveSpeechNotifier, LiveSpeechState>((ref) {
      return LiveSpeechNotifier(ref);
    });

/// Voice uses the language selected on the lesson screen (language list). When user switches
/// language there, we reconnect so LLM and TTS use the new language.
final voiceTargetLanguageCodeProvider = Provider<String>((ref) {
  final lang = ref.watch(languageProvider);
  return _normalizeLangCode(lang.code);
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

enum VoiceState { idle, warming, listening, processing, speaking, error }

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
  bool _isRecording = false;
  bool _isStartingRecording = false;
  bool _stopRequestedWhileStarting = false;
  DateTime? _recordingStartedAt;
  int _recordedBytes = 0;

  static const int _minimumRecordingMs = 700;
  static const int _minimumRecordingBytes = 12000;

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
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  /// Connect to voice WebSocket. Uses [targetLanguageCode] from profile when not provided.
  Future<void> connect({String? targetLanguageCode}) async {
    try {
      _disconnectChannel(); // close existing if any
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        state = state.copyWith(
          status: VoiceState.error,
          errorMessage: "Not authenticated",
        );
        return;
      }
      final raw = targetLanguageCode ?? _ref.read(languageProvider).code;
      final langCode = _normalizeLangCode(raw);
      state = state.copyWith(status: VoiceState.warming, errorMessage: null);
      await _prewarmVoiceBackend(accessToken, langCode);
      final url = _getWsUrl(langCode);
      final protocols = <String>['voice.v1', 'bearer.$accessToken'];
      debugPrint('Attempting to connect to WS (secured subprotocol auth)');
      _channel = WebSocketChannel.connect(Uri.parse(url), protocols: protocols);
      await _channel!.ready;
      debugPrint('WebSocket Connection Established');
      SemanticsService.announce('Voice WebSocket connected', TextDirection.ltr);
      state = state.copyWith(status: VoiceState.idle, errorMessage: null);

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            debugPrint('WS Text: $message');
            if (message.startsWith('AUDIO:')) {
              final rest = message.substring(6);
              final parts = rest.split(',');
              if (parts.length >= 2) {
                _lastAudioCodec = parts[0].trim().toLowerCase();
                _lastAudioSampleRate = int.tryParse(parts[1].trim()) ?? 24000;
              }
            } else if (message.startsWith('TEXT:')) {
              final text = message.substring(5).trim();
              state = state.copyWith(
                status: VoiceState.speaking,
                lastTranscript: text,
                errorMessage: null,
              );
            } else if (message.startsWith('ERROR:')) {
              final error = message.substring(6).trim();
              state = state.copyWith(
                status: VoiceState.error,
                errorMessage: error == 'No speech detected'
                    ? 'No speech detected. Hold the button and speak clearly.'
                    : error,
              );
            }
          } else {
            debugPrint(
              'WS Binary: ${message.runtimeType} length: ${(message as List).length}',
            );
            _playAudio(message);
          }
        },
        onError: (error) {
          debugPrint('WS Error callback: $error');
          state = state.copyWith(
            status: VoiceState.error,
            errorMessage: "WS Error: $error",
          );
        },
        onDone: () {
          debugPrint('WS Closed');
          state = state.copyWith(
            status: VoiceState.idle,
            errorMessage: "Disconnected",
          );
        },
      );
    } catch (e) {
      debugPrint('WS Connection Exception: $e');
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: "Conn Error: $e",
      );
    }
  }

  Future<void> _prewarmVoiceBackend(
    String accessToken,
    String languageCode,
  ) async {
    final uri = Uri.parse('$defaultBackendBaseUrl/api/v1/chat/voice/prewarm');
    try {
      await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'languageCode': languageCode}),
          )
          .timeout(const Duration(seconds: 10))
          .then((_) {
            debugPrint('Voice prewarm completed successfully');
          });
    } catch (e) {
      debugPrint('Voice prewarm failed: $e');
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
    if (_isRecording || _isStartingRecording) return;
    _isStartingRecording = true;
    _stopRequestedWhileStarting = false;
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: "Mic permission permanently denied. Open Settings.",
      );
      await openAppSettings();
      _isStartingRecording = false;
      return;
    }

    if (!status.isGranted) {
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: "Mic permission denied",
      );
      _isStartingRecording = false;
      return;
    }

    if (_channel == null) await connect();

    state = state.copyWith(status: VoiceState.listening);
    _isRecording = true;
    _recordingStartedAt = DateTime.now();
    _recordedBytes = 0;

    // Create a StreamController to receive audio from recorder and forward to WS
    final recordingDataController = StreamController<Uint8List>();
    _recorderSubscription = recordingDataController.stream.listen((buffer) {
      _recordedBytes += buffer.length;
      if (_channel != null) {
        _channel!.sink.add(buffer);
      }
    });

    try {
      await _recorder!.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );
    } catch (e) {
      _isRecording = false;
      _isStartingRecording = false;
      _stopRequestedWhileStarting = false;
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Could not start recording: $e',
      );
      return;
    }
    _isStartingRecording = false;

    if (_stopRequestedWhileStarting) {
      _stopRequestedWhileStarting = false;
      await stopRecording();
    }
  }

  Future<void> stopRecording() async {
    if (_isStartingRecording && !_isRecording) {
      _stopRequestedWhileStarting = true;
      return;
    }
    if (!_isRecording) return;
    final startedAt = _recordingStartedAt;
    _isRecording = false;
    await _recorder!.stopRecorder();
    if (_recorderSubscription != null) {
      await _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    final elapsedMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsedMs < _minimumRecordingMs ||
        _recordedBytes < _minimumRecordingBytes) {
      debugPrint(
        'Voice recording too short: ${elapsedMs}ms, $_recordedBytes bytes',
      );
      state = state.copyWith(
        status: VoiceState.idle,
        errorMessage: "Hold a little longer and speak clearly.",
      );
      return;
    }

    // Send End-Of-Speech signal
    if (_channel != null) {
      debugPrint('Sending EOS signal');
      _channel!.sink.add("EOS");
    }

    state = state.copyWith(status: VoiceState.processing);
  }

  Future<void> _playAudio(dynamic data) async {
    state = state.copyWith(status: VoiceState.speaking);
    final Uint8List bytes = data is Uint8List
        ? data
        : Uint8List.fromList(List<int>.from(data));
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                current == AppLocaleNotifier.en
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: current == AppLocaleNotifier.en
                    ? Theme.of(ctx).colorScheme.primary
                    : Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                current == AppLocaleNotifier.ro
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: current == AppLocaleNotifier.ro
                    ? Theme.of(ctx).colorScheme.primary
                    : Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // When effective language changes (or on first open), connect/reconnect with current target language
    ref.listen(voiceTargetLanguageCodeProvider, (prev, next) {
      if (next.isEmpty) return;
      if (prev == null) {
        // First time opening voice screen: connect with current language (e.g. from lecon topic)
        notifier.connect(targetLanguageCode: next);
      } else if (prev != next) {
        // User changed language (e.g. switched topic on lecon then came back): reconnect
        notifier.disconnect();
        notifier.connect(targetLanguageCode: next);
      }
    });

    final textDirection = Directionality.of(context);
    ref.listen(liveSpeechProvider, (previous, next) {
      if (previous?.errorMessage != null && next.errorMessage == null) {
        SemanticsService.announce('Voice connection ready', textDirection);
      }
    });

    final isRecording = speechState.status == VoiceState.listening;
    final isWarming = speechState.status == VoiceState.warming;
    final voiceButtonLabel = isRecording
        ? 'Stop recording and process audio'
        : isWarming
        ? 'Voice models warming up, please wait'
        : 'Start voice recording';
    final voiceButtonHint = isRecording
        ? 'Release to stop recording and send audio for processing'
        : isWarming
        ? 'Models are loading, please wait a moment'
        : 'Press and hold to record your voice';

    final isActiveSession =
        speechState.status == VoiceState.listening ||
        speechState.status == VoiceState.processing ||
        speechState.status == VoiceState.speaking;

    return PopScope(
      canPop: !isActiveSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('End voice session?'),
            content: const Text(
              'The voice session is still active. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          notifier.disconnect();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          title: Text(
            s.liveAssistant,
            style: TextStyle(color: scheme.onSurface),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.language_rounded, color: scheme.onSurface),
              onPressed: () => _showAppLanguagePicker(context, ref),
              tooltip: s.appLanguage,
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        // AI speech bubble at the top with current reply text
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(1),
                          child: Semantics(
                            container: true,
                            liveRegion: true,
                            label: 'Assistant response',
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: speechState.lastTranscript.isEmpty
                                    ? 0.0
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : scheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    speechState.lastTranscript.isEmpty
                                        ? s.tapHoldToSpeak
                                        : speechState.lastTranscript,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (speechState.errorMessage != null)
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(2),
                            child: Semantics(
                              liveRegion: true,
                              label: 'Voice error',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  speechState.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(3),
                          child: MergeSemantics(
                            child: Semantics(
                              button: true,
                              enabled: true,
                              label: voiceButtonLabel,
                              hint: voiceButtonHint,
                              child: GestureDetector(
                                onTapDown: isWarming
                                    ? null
                                    : (_) => notifier.startRecording(),
                                onTapUp: isWarming
                                    ? null
                                    : (_) => notifier.stopRecording(),
                                onTapCancel: isWarming
                                    ? null
                                    : () => notifier.stopRecording(),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width:
                                        speechState.status ==
                                            VoiceState.speaking
                                        ? 220
                                        : 200,
                                    height:
                                        speechState.status ==
                                            VoiceState.speaking
                                        ? 220
                                        : 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getColor(
                                        speechState.status,
                                        scheme,
                                      ),
                                      boxShadow: [
                                        if (speechState.status ==
                                                VoiceState.listening ||
                                            speechState.status ==
                                                VoiceState.speaking)
                                          BoxShadow(
                                            color: scheme.primary.withValues(
                                              alpha:
                                                  speechState.status ==
                                                      VoiceState.speaking
                                                  ? 0.8
                                                  : 0.5,
                                            ),
                                            blurRadius:
                                                speechState.status ==
                                                    VoiceState.speaking
                                                ? 60
                                                : 40,
                                            spreadRadius:
                                                speechState.status ==
                                                    VoiceState.speaking
                                                ? 30
                                                : 20,
                                          ),
                                      ],
                                    ),
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        _getIcon(speechState.status),
                                        size: 80,
                                        color: _getIconColor(
                                          speechState.status,
                                          scheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(4),
                          child: Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              _getStatusText(speechState.status, s),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(5),
                          child: Text(
                            s.holdToSpeak,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getColor(VoiceState status, ColorScheme scheme) {
    return switch (status) {
      VoiceState.listening => scheme.primary,
      VoiceState.processing => AppColors.secondary,
      VoiceState.speaking => Colors.green,
      VoiceState.error => scheme.error,
      VoiceState.warming => Colors.orange,
      VoiceState.idle => scheme.surfaceContainerHighest,
    };
  }

  IconData _getIcon(VoiceState status) {
    return switch (status) {
      VoiceState.listening => FontAwesomeIcons.microphoneLines,
      VoiceState.processing => FontAwesomeIcons.brain,
      VoiceState.speaking => FontAwesomeIcons.volumeHigh,
      VoiceState.warming => FontAwesomeIcons.hourglass,
      VoiceState.idle || VoiceState.error => FontAwesomeIcons.microphone,
    };
  }

  Color _getIconColor(VoiceState status, ColorScheme scheme) {
    return switch (status) {
      VoiceState.listening => scheme.onPrimary,
      VoiceState.processing => scheme.onSecondary,
      VoiceState.speaking => Colors.white,
      VoiceState.error => scheme.onError,
      VoiceState.warming => Colors.white,
      VoiceState.idle => scheme.onSurface,
    };
  }

  String _getStatusText(VoiceState status, AppStringsData s) {
    return switch (status) {
      VoiceState.listening => s.listening,
      VoiceState.processing => s.liveThinking,
      VoiceState.speaking => s.liveSpeaking,
      VoiceState.warming => 'Warming up…',
      VoiceState.idle || VoiceState.error => s.tapHoldToSpeak,
    };
  }
}
