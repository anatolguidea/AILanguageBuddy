import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
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
import '../../../../core/config.dart';
import '../../data/models/voice_models.dart';

// Helper to convert HTTP URL to WS URL
String _getWsUrl(String? userId, String? accessToken) {
  final uri = Uri.parse(defaultBackendBaseUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final queryParameters = <String, String>{};
  if (userId != null && userId.isNotEmpty) {
    queryParameters['userId'] = userId;
  }
  if (accessToken != null && accessToken.isNotEmpty) {
    queryParameters['token'] = accessToken;
  }

  return Uri(
    scheme: scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/ws/voice',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

final liveSpeechProvider =
    StateNotifierProvider<LiveSpeechNotifier, LiveSpeechState>((ref) {
      return LiveSpeechNotifier();
    });

enum VoiceState { idle, listening, processing, speaking, error }

const int _supportedVoiceProtocolVersion = 1;
const int _defaultAudioPrebufferChunks = 2;
const int _defaultAudioPrebufferBytes = 12 * 1024;
const int _defaultAudioQueueHighWatermarkBytes = 2 * 1024 * 1024;
const int _defaultAudioQueueTrimTargetBytes = 1536 * 1024;
const int _minAudioQueueHighWatermarkBytes = 768 * 1024;
const int _minAudioQueueTrimTargetBytes = 512 * 1024;
const int _audioQueueHardCapBytes = 8 * 1024 * 1024;
const int _playbackBatchTargetBytes = 48 * 1024;
const int _playbackBatchMaxChunks = 8;
const int _ttsSampleRate = 24000;
const int _pcm16BytesPerSample = 2;
const int _maxStreamDrainFallbackMs = 90000;
const Duration _baseReconnectDelay = Duration(seconds: 1);
const Duration _maxReconnectDelay = Duration(seconds: 20);

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
  WebSocketChannel? _channel;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _recorderSubscription;
  StreamController<Uint8List>? _recordingDataController;
  StreamSubscription? _channelSubscription;
  Future<void>? _initFuture;
  final Queue<Uint8List> _audioChunkQueue = Queue<Uint8List>();
  int _queuedAudioBytes = 0;
  bool _isChunkPlaybackActive = false;
  bool _audioStreamEnded = false;
  bool _expectingAudioEnd = false;
  bool _streamPlaybackSessionActive = false;
  Timer? _streamDrainFallbackTimer;
  int _audioPrebufferChunks = _defaultAudioPrebufferChunks;
  int _audioPrebufferBytes = _defaultAudioPrebufferBytes;
  int _audioQueueHighWatermarkBytes = _defaultAudioQueueHighWatermarkBytes;
  int _audioQueueTrimTargetBytes = _defaultAudioQueueTrimTargetBytes;
  int _receivedChunkCount = 0;
  int _droppedChunkCount = 0;
  int _peakQueuedAudioBytes = 0;
  int _currentStreamTotalBytes = 0;
  DateTime? _streamPlaybackStartedAt;
  DateTime? _audioStreamStartedAt;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;

  LiveSpeechNotifier() : super(LiveSpeechState()) {
    _initFuture = _init();
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

  Future<void> connect({bool manual = true}) async {
    if (_isDisposed || _isConnecting) {
      return;
    }
    if (manual) {
      _cancelReconnect();
      _reconnectAttempts = 0;
    }
    _isConnecting = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final url = _getWsUrl(userId, accessToken);
      print('Attempting to connect to WS: $url');
      await _channelSubscription?.cancel();
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready; // Wait for connection to be established
      print('WebSocket Connection Established');
      _reconnectAttempts = 0;
      state = state.copyWith(errorMessage: "Connected to Server");

      _channelSubscription = _channel!.stream.listen(
        (message) {
          if (message is String) {
            // print('WS Text: $message'); // Commented out to reduce noise
            _handleTextEvent(message);
          } else {
            final length = message is Uint8List
                ? message.length
                : (message as List).length;
            // print('WS Binary: ${message.runtimeType} length: $length'); // Commented out
            final Uint8List bytes = message is Uint8List
                ? message
                : Uint8List.fromList(List<int>.from(message));
            if (_expectingAudioEnd) {
              _enqueueAudioChunk(bytes);
              _drainChunkPlayback();
            } else {
              _playAudio(bytes);
            }
          }
        },
        onError: (error) {
          print('WS Error callback: $error');
          _channel = null;
          _transitionStatus(VoiceState.error, errorMessage: "WS Error: $error");
          _scheduleReconnect("error");
          unawaited(_stopStreamingPlayerIfNeeded());
        },
        onDone: () {
          print('WS Closed');
          _channel = null;
          _transitionStatus(VoiceState.idle, errorMessage: "Disconnected");
          _resetAudioStreamingState();
          unawaited(_stopStreamingPlayerIfNeeded());
          _scheduleReconnect("closed");
        },
      );
    } catch (e) {
      print('WS Connection Exception: $e');
      _transitionStatus(VoiceState.error, errorMessage: "Conn Error: $e");
      _scheduleReconnect("connect_failed");
    } finally {
      _isConnecting = false;
    }
  }

  void _handleTextEvent(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final event = VoiceEventMessage.fromJson(decoded);
        if (event.version > _supportedVoiceProtocolVersion) {
          _transitionStatus(
            VoiceState.error,
            errorMessage:
                "Unsupported voice protocol version: ${event.version} (app supports $_supportedVoiceProtocolVersion)",
          );
          return;
        }
        if (event.event == VoiceEventType.error) {
          _transitionStatus(VoiceState.error, errorMessage: event.message);
          _resetAudioStreamingState();
        } else if (event.event == VoiceEventType.transcript) {
          state = state.copyWith(
            lastTranscript: event.message,
            errorMessage: null,
          );
        } else if (event.event == VoiceEventType.partialTranscript) {
          state = state.copyWith(
            lastTranscript: event.message,
            errorMessage: null,
          );
        } else if (event.event == VoiceEventType.processing) {
          _transitionStatus(VoiceState.processing, errorMessage: null);
        } else if (event.event == VoiceEventType.connected) {
          state = state.copyWith(errorMessage: "Connected to Server");
        } else if (event.event == VoiceEventType.assistantPartial) {
          _transitionStatus(VoiceState.processing, errorMessage: null);
        } else if (event.event == VoiceEventType.assistantText) {
          _beginAudioStream();
        } else if (event.event == VoiceEventType.audioEnd) {
          _expectingAudioEnd = false;
          _audioStreamEnded = true;
          _logAudioTelemetry();
          _drainChunkPlayback();
          _armStreamDrainFallback();
        } else if (event.event == VoiceEventType.jitterConfig) {
          _applyJitterConfig(event.data);
        }
        return;
      }
    } catch (_) {
      // Legacy/plain server text fallback.
    }

    if (message.startsWith("ERROR:")) {
      _transitionStatus(VoiceState.error, errorMessage: message);
      _resetAudioStreamingState();
    }
  }

  Future<void> startRecording() async {
    await _initFuture;
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      _transitionStatus(
        VoiceState.error,
        errorMessage: "Mic permission permanently denied. Open Settings.",
      );
      await openAppSettings();
      return;
    }

    if (!status.isGranted) {
      _transitionStatus(
        VoiceState.error,
        errorMessage: "Mic permission denied",
      );
      return;
    }

    if (_channel == null) {
      await connect(manual: false);
    }
    if (_channel == null) {
      _transitionStatus(
        VoiceState.error,
        errorMessage: "Voice connection unavailable",
      );
      return;
    }
    await _stopStreamingPlayerIfNeeded();
    _resetAudioStreamingState();
    _channel!.sink.add(
      jsonEncode(const VoiceControlMessage(VoiceEventType.startTurn).toJson()),
    );

    _transitionStatus(VoiceState.listening);

    // Create a StreamController to receive audio from recorder and forward to WS.
    await _recorderSubscription?.cancel();
    await _recordingDataController?.close();
    _recordingDataController = StreamController<Uint8List>();
    _recorderSubscription = _recordingDataController!.stream.listen((buffer) {
      if (_channel != null) {
        _channel!.sink.add(buffer);
      }
    });

    await _recorder!.startRecorder(
      toStream: _recordingDataController!.sink,
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
    if (_recordingDataController != null) {
      await _recordingDataController!.close();
      _recordingDataController = null;
    }

    // Send end-of-turn signal
    if (_channel != null) {
      print("Sending end_turn signal");
      _channel!.sink.add(
        jsonEncode(const VoiceControlMessage(VoiceEventType.endTurn).toJson()),
      );
    }

    _transitionStatus(VoiceState.processing);
  }

  Future<void> _playAudio(dynamic data) async {
    await _stopStreamingPlayerIfNeeded();
    _transitionStatus(VoiceState.speaking);
    final Uint8List bytes = data is Uint8List
        ? data
        : Uint8List.fromList(List<int>.from(data));

    await _player!.startPlayer(
      fromDataBuffer: bytes,
      sampleRate: 24000, // TTS output rate (Chatterbox usually 24k)
      codec: Codec.pcm16,
      whenFinished: () {
        _transitionStatus(VoiceState.idle);
      },
    );
  }

  void _drainChunkPlayback() {
    if (_isChunkPlaybackActive) return;
    _isChunkPlaybackActive = true;
    unawaited(_drainChunkPlaybackAsync());
  }

  Future<void> _drainChunkPlaybackAsync() async {
    try {
      await _ensureStreamingPlayerStarted();
      if (!_audioStreamEnded &&
          (_audioChunkQueue.length < _audioPrebufferChunks ||
              _queuedAudioBytes < _audioPrebufferBytes)) {
        return;
      }
      while (_audioChunkQueue.isNotEmpty) {
        final batch = _dequeuePlaybackBatch();
        if (batch.isEmpty) {
          break;
        }
        _transitionStatus(VoiceState.speaking);
        _streamPlaybackStartedAt ??= DateTime.now();
        await _player!.feedUint8FromStream(batch);
      }
      if (_audioStreamEnded && _audioChunkQueue.isEmpty) {
        // Wait for onBufferUnderflow callback before final stop to avoid
        // cutting off buffered audio on iOS.
        _armStreamDrainFallback();
      }
    } finally {
      _isChunkPlaybackActive = false;
      // Next chunk arrival or audio_end will trigger another drain pass.
    }
  }

  Uint8List _dequeuePlaybackBatch() {
    if (_audioChunkQueue.isEmpty) {
      return Uint8List(0);
    }

    final chunks = <Uint8List>[];
    int bytes = 0;
    int count = 0;

    // If stream has ended, flush everything as one contiguous buffer.
    final targetBytes = _audioStreamEnded
        ? _queuedAudioBytes
        : _playbackBatchTargetBytes;
    final maxChunks = _audioStreamEnded
        ? _audioChunkQueue.length
        : _playbackBatchMaxChunks;

    while (_audioChunkQueue.isNotEmpty &&
        count < maxChunks &&
        (bytes < targetBytes || count == 0)) {
      final chunk = _audioChunkQueue.removeFirst();
      _queuedAudioBytes -= chunk.length;
      chunks.add(chunk);
      bytes += chunk.length;
      count += 1;
    }

    if (chunks.length == 1) {
      return chunks.first;
    }
    return _mergeChunks(chunks, bytes);
  }

  Uint8List _mergeChunks(List<Uint8List> chunks, int totalBytes) {
    final merged = Uint8List(totalBytes);
    int offset = 0;
    for (final chunk in chunks) {
      merged.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return merged;
  }

  void _enqueueAudioChunk(Uint8List chunk) {
    _audioChunkQueue.addLast(chunk);
    _queuedAudioBytes += chunk.length;
    _currentStreamTotalBytes += chunk.length;
    _receivedChunkCount += 1;
    if (_queuedAudioBytes > _peakQueuedAudioBytes) {
      _peakQueuedAudioBytes = _queuedAudioBytes;
    }
    while (_queuedAudioBytes > _audioQueueHighWatermarkBytes &&
        _audioChunkQueue.isNotEmpty &&
        (_audioStreamEnded || _queuedAudioBytes > _audioQueueHardCapBytes)) {
      // Preserve stream start intelligibility: drop newest overflow chunks
      // instead of oldest chunks that contain the first words.
      final dropped = _audioChunkQueue.removeLast();
      _queuedAudioBytes -= dropped.length;
      _droppedChunkCount += 1;
      if (_queuedAudioBytes <= _audioQueueTrimTargetBytes) {
        break;
      }
    }
  }

  void _beginAudioStream() {
    _expectingAudioEnd = true;
    _audioStreamEnded = false;
    _audioChunkQueue.clear();
    _queuedAudioBytes = 0;
    _receivedChunkCount = 0;
    _droppedChunkCount = 0;
    _peakQueuedAudioBytes = 0;
    _currentStreamTotalBytes = 0;
    _streamPlaybackStartedAt = null;
    _audioStreamStartedAt = DateTime.now();
  }

  Future<void> _ensureStreamingPlayerStarted() async {
    if (_streamPlaybackSessionActive) {
      return;
    }
    await _player!.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: 1,
      sampleRate: _ttsSampleRate,
      bufferSize: 8192,
      onBufferUnderflow: _onStreamingUnderflow,
    );
    _streamPlaybackSessionActive = true;
  }

  void _onStreamingUnderflow() {
    if (_isDisposed) {
      return;
    }
    if (_audioStreamEnded && _audioChunkQueue.isEmpty) {
      unawaited(_finishStreamPlayback());
      return;
    }
    if (_audioChunkQueue.isNotEmpty) {
      _drainChunkPlayback();
    }
  }

  void _armStreamDrainFallback() {
    if (!_audioStreamEnded || _audioChunkQueue.isNotEmpty) {
      return;
    }
    final startedAt = _streamPlaybackStartedAt;
    final estimatedDurationMs =
        (_currentStreamTotalBytes * 1000) ~/
        (_ttsSampleRate * _pcm16BytesPerSample);
    final elapsedMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    int waitMs = estimatedDurationMs - elapsedMs + 450;
    if (waitMs < 800) {
      waitMs = 800;
    } else if (waitMs > _maxStreamDrainFallbackMs) {
      waitMs = _maxStreamDrainFallbackMs;
    }
    _streamDrainFallbackTimer?.cancel();
    _streamDrainFallbackTimer = Timer(Duration(milliseconds: waitMs), () {
      unawaited(_finishStreamPlayback());
    });
  }

  Future<void> _finishStreamPlayback() async {
    _streamDrainFallbackTimer?.cancel();
    _streamDrainFallbackTimer = null;
    if (!_audioStreamEnded || _audioChunkQueue.isNotEmpty) {
      return;
    }
    await _stopStreamingPlayerIfNeeded();
    _transitionStatus(VoiceState.idle);
  }

  Future<void> _stopStreamingPlayerIfNeeded() async {
    _streamDrainFallbackTimer?.cancel();
    _streamDrainFallbackTimer = null;
    if (!_streamPlaybackSessionActive) {
      return;
    }
    try {
      await _player!.stopPlayer();
    } catch (_) {
      // Best effort stop; player will be closed on dispose anyway.
    } finally {
      _streamPlaybackSessionActive = false;
      _streamPlaybackStartedAt = null;
    }
  }

  void _logAudioTelemetry() {
    /*
    final startedAt = _audioStreamStartedAt;
    final durationMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    print(
      'Voice stream telemetry: chunks=$_receivedChunkCount dropped=$_droppedChunkCount '
      'peakQueueBytes=$_peakQueuedAudioBytes durationMs=$durationMs',
    );
    */
  }

  int? _asPositiveInt(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return null;
  }

  void _applyJitterConfig(Map<String, dynamic>? data) {
    if (data == null) {
      return;
    }
    final prebufferChunks =
        _asPositiveInt(data['prebufferChunks']) ?? _audioPrebufferChunks;
    final prebufferBytes =
        _asPositiveInt(data['prebufferBytes']) ?? _audioPrebufferBytes;
    final highWatermark =
        _asPositiveInt(data['queueHighWatermarkBytes']) ??
        _audioQueueHighWatermarkBytes;
    int trimTarget =
        _asPositiveInt(data['queueTrimTargetBytes']) ??
        _audioQueueTrimTargetBytes;
    if (trimTarget >= highWatermark) {
      trimTarget = (highWatermark * 2) ~/ 3;
    }
    final boundedHighWatermark =
        highWatermark < _minAudioQueueHighWatermarkBytes
        ? _minAudioQueueHighWatermarkBytes
        : highWatermark;
    int boundedTrimTarget = trimTarget < _minAudioQueueTrimTargetBytes
        ? _minAudioQueueTrimTargetBytes
        : trimTarget;
    if (boundedTrimTarget >= boundedHighWatermark) {
      boundedTrimTarget = (boundedHighWatermark * 2) ~/ 3;
    }

    _audioPrebufferChunks = prebufferChunks;
    _audioPrebufferBytes = prebufferBytes;
    _audioQueueHighWatermarkBytes = boundedHighWatermark;
    _audioQueueTrimTargetBytes = boundedTrimTarget;
    print(
      'Applied jitter config: prebufferChunks=$_audioPrebufferChunks '
      'prebufferBytes=$_audioPrebufferBytes '
      'queueHighWatermarkBytes=$_audioQueueHighWatermarkBytes '
      'queueTrimTargetBytes=$_audioQueueTrimTargetBytes',
    );
  }

  void _resetAudioStreamingState() {
    _streamDrainFallbackTimer?.cancel();
    _streamDrainFallbackTimer = null;
    _audioChunkQueue.clear();
    _queuedAudioBytes = 0;
    _isChunkPlaybackActive = false;
    _audioStreamEnded = false;
    _expectingAudioEnd = false;
    _receivedChunkCount = 0;
    _droppedChunkCount = 0;
    _peakQueuedAudioBytes = 0;
    _currentStreamTotalBytes = 0;
    _streamPlaybackStartedAt = null;
    _audioStreamStartedAt = null;
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Duration _nextReconnectDelay() {
    final cappedAttempt = _reconnectAttempts > 6 ? 6 : _reconnectAttempts;
    final multiplier = 1 << cappedAttempt;
    final seconds = _baseReconnectDelay.inSeconds * multiplier;
    final bounded = seconds > _maxReconnectDelay.inSeconds
        ? _maxReconnectDelay.inSeconds
        : seconds;
    return Duration(seconds: bounded);
  }

  void _scheduleReconnect(String reason) {
    if (_isDisposed || _reconnectTimer != null) {
      return;
    }
    if (_isConnecting && reason != "connect_failed") {
      return;
    }
    if (state.status == VoiceState.listening ||
        state.status == VoiceState.processing ||
        state.status == VoiceState.speaking) {
      return;
    }
    final delay = _nextReconnectDelay();
    _reconnectAttempts += 1;
    print(
      'Scheduling WS reconnect in ${delay.inSeconds}s (reason=$reason attempt=$_reconnectAttempts)',
    );
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      await connect(manual: false);
    });
  }

  void _transitionStatus(
    VoiceState next, {
    String? errorMessage,
    String? lastTranscript,
  }) {
    final current = state.status;
    final allowed = switch (current) {
      VoiceState.idle => {
        VoiceState.idle,
        VoiceState.listening,
        VoiceState.error,
      },
      VoiceState.listening => {
        VoiceState.listening,
        VoiceState.processing,
        VoiceState.idle,
        VoiceState.error,
      },
      VoiceState.processing => {
        VoiceState.processing,
        VoiceState.speaking,
        VoiceState.idle,
        VoiceState.error,
      },
      VoiceState.speaking => {
        VoiceState.speaking,
        VoiceState.idle,
        VoiceState.error,
        VoiceState.listening,
      },
      VoiceState.error => {
        VoiceState.error,
        VoiceState.idle,
        VoiceState.listening,
      },
    };
    if (!allowed.contains(next)) return;
    state = state.copyWith(
      status: next,
      errorMessage: errorMessage ?? state.errorMessage,
      lastTranscript: lastTranscript ?? state.lastTranscript,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelReconnect();
    unawaited(_stopStreamingPlayerIfNeeded());
    _recorderSubscription?.cancel();
    _recordingDataController?.close();
    _channelSubscription?.cancel();
    _resetAudioStreamingState();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _channel?.sink.close();
    super.dispose();
  }
}

class LiveSpeechPage extends ConsumerWidget {
  const LiveSpeechPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(liveSpeechProvider);
    final notifier = ref.read(liveSpeechProvider.notifier);
    final bool hasTranscript = speechState.lastTranscript.trim().isNotEmpty;
    final bool hasError = speechState.errorMessage != null;
    final String bubbleText = hasError
        ? speechState.errorMessage!
        : (hasTranscript
              ? speechState.lastTranscript
              : _statusPrompt(speechState.status));

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Live Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceDark, AppColors.backgroundBlack],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 760
                  ? 760.0
                  : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        _SpeechBubbleCard(
                          title: _statusTitle(speechState.status),
                          text: bubbleText,
                          isError: hasError,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onLongPressStart: (_) => notifier.startRecording(),
                          onLongPressEnd: (_) => notifier.stopRecording(),
                          child: _VoiceOrbWithWaves(status: speechState.status),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _statusTitle(speechState.status),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusHint(speechState.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.surfaceElevated,
                            ),
                            color: AppColors.surfaceDark.withValues(
                              alpha: 0.72,
                            ),
                          ),
                          child: TextButton.icon(
                            onPressed: () => notifier.connect(),
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              "Reconnect voice channel",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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

  static String _statusTitle(VoiceState status) => switch (status) {
    VoiceState.listening => "Listening",
    VoiceState.processing => "Thinking",
    VoiceState.speaking => "Speaking",
    VoiceState.error => "Connection Issue",
    VoiceState.idle => "Hold to Speak",
  };

  static String _statusHint(VoiceState status) => switch (status) {
    VoiceState.listening => "Keep holding while you talk",
    VoiceState.processing => "Generating your response",
    VoiceState.speaking => "AI is replying in voice",
    VoiceState.error => "Tap reconnect and try again",
    VoiceState.idle => "Press and hold the orb to start",
  };

  static String _statusPrompt(VoiceState status) => switch (status) {
    VoiceState.listening => "I'm listening...",
    VoiceState.processing => "Let me think about that...",
    VoiceState.speaking => "Here is my response...",
    VoiceState.error => "I hit a connection issue. Try reconnecting.",
    VoiceState.idle => "Ask me anything in English. I'll answer by voice.",
  };
}

class _SpeechBubbleCard extends StatelessWidget {
  final String title;
  final String text;
  final bool isError;

  const _SpeechBubbleCard({
    required this.title,
    required this.text,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isError ? AppColors.error : AppColors.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppColors.surfaceDark.withValues(alpha: 0.88),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.42),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.35,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: -8,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.88),
                border: Border(
                  right: BorderSide(
                    color: borderColor.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceOrbWithWaves extends StatefulWidget {
  final VoiceState status;

  const _VoiceOrbWithWaves({required this.status});

  @override
  State<_VoiceOrbWithWaves> createState() => _VoiceOrbWithWavesState();
}

class _VoiceOrbWithWavesState extends State<_VoiceOrbWithWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isWaveActive =>
      widget.status == VoiceState.listening ||
      widget.status == VoiceState.processing ||
      widget.status == VoiceState.speaking;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    if (_isWaveActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceOrbWithWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isWaveActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_isWaveActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbColor = switch (widget.status) {
      VoiceState.listening => AppColors.primary,
      VoiceState.processing => AppColors.secondary,
      VoiceState.speaking => AppColors.avatarListening,
      VoiceState.error => AppColors.error,
      VoiceState.idle => AppColors.surfaceElevated,
    };
    final icon = switch (widget.status) {
      VoiceState.listening => FontAwesomeIcons.microphoneLines,
      VoiceState.processing => FontAwesomeIcons.brain,
      VoiceState.speaking => FontAwesomeIcons.volumeHigh,
      VoiceState.error => FontAwesomeIcons.triangleExclamation,
      VoiceState.idle => FontAwesomeIcons.microphone,
    };

    return SizedBox(
      width: 290,
      height: 290,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(290, 290),
                painter: _WaveRingsPainter(
                  progress: _controller.value,
                  active: _isWaveActive,
                  color: orbColor,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      orbColor.withValues(alpha: 0.92),
                      orbColor.withValues(alpha: 0.58),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orbColor.withValues(
                        alpha: _isWaveActive ? 0.35 : 0.14,
                      ),
                      blurRadius: _isWaveActive ? 36 : 16,
                      spreadRadius: _isWaveActive ? 10 : 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 58),
              ),
              Positioned(
                bottom: 40,
                child: Text(
                  "HOLD TO TALK",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaveRingsPainter extends CustomPainter {
  final double progress;
  final bool active;
  final Color color;

  _WaveRingsPainter({
    required this.progress,
    required this.active,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final center = Offset(size.width / 2, size.height / 2);
    const minRadius = 92.0;
    const maxExpand = 88.0;

    for (int i = 0; i < 3; i++) {
      final local = (progress + (i * 0.28)) % 1.0;
      final radius = minRadius + (maxExpand * local);
      final alpha = (1.0 - local) * (0.42 - (i * 0.07));
      if (alpha <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - (i * 0.35)
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveRingsPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        active != oldDelegate.active ||
        color != oldDelegate.color;
  }
}
