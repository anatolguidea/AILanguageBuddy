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

// Helper to convert HTTP URL to WS URL
String _getWsUrl(String? userId) {
  final uri = Uri.parse(kBaseUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final host = uri.host;
  final port = uri.port;
  String url = '$scheme://$host:$port/ws/voice';
  if (userId != null) {
    url += '?userId=$userId';
  }
  return url;
}

final liveSpeechProvider = StateNotifierProvider<LiveSpeechNotifier, LiveSpeechState>((ref) {
  return LiveSpeechNotifier();
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
  WebSocketChannel? _channel;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _recorderSubscription;

  LiveSpeechNotifier() : super(LiveSpeechState()) {
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

  Future<void> connect() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final url = _getWsUrl(userId);
      print('Attempting to connect to WS: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready; // Wait for connection to be established
      print('WebSocket Connection Established');
      state = state.copyWith(errorMessage: "Connected to Server");

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            print('WS Text: $message');
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
    
    await _player!.startPlayer(
      fromDataBuffer: bytes,
      sampleRate: 24000, // TTS output rate (Chatterbox usually 24k)
      codec: Codec.pcm16,
      whenFinished: () {
        state = state.copyWith(status: VoiceState.idle);
      },
    );
  }

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Live Assistant'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Info
            if (speechState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  speechState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
              
            // Debug / Test Connection
            TextButton.icon(
              onPressed: () => notifier.connect(),
              icon: const Icon(Icons.refresh, color: Colors.white54),
              label: const Text("Reconnect WS", style: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 20),

            // Visualizer Ring
            GestureDetector(
              onLongPressStart: (_) => notifier.startRecording(),
              onLongPressEnd: (_) => notifier.stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColor(speechState.status),
                  boxShadow: [
                    if (speechState.status == VoiceState.listening)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      )
                  ],
                ),
                child: Icon(
                  _getIcon(speechState.status),
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _getStatusText(speechState.status),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Hold to Speak",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(VoiceState status) {
    switch (status) {
      case VoiceState.listening:
        return AppColors.primary;
      case VoiceState.processing:
        return AppColors.secondary;
      case VoiceState.speaking:
        return Colors.green;
      case VoiceState.error:
        return AppColors.error;
      default:
        return AppColors.surfaceElevated;
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

  String _getStatusText(VoiceState status) {
    switch (status) {
      case VoiceState.listening:
        return "Listening...";
      case VoiceState.processing:
        return "Thinking...";
      case VoiceState.speaking:
        return "Speaking...";
      default:
        return "Tap & Hold to Speak";
    }
  }
}
