enum VoiceEventType {
  connected('connected'),
  processing('processing'),
  partialTranscript('partial_transcript'),
  transcript('transcript'),
  assistantPartial('assistant_partial'),
  assistantText('assistant_text'),
  audioEnd('audio_end'),
  jitterConfig('jitter_config'),
  error('error'),
  startTurn('start_turn'),
  endTurn('end_turn');

  final String wireValue;
  const VoiceEventType(this.wireValue);

  static VoiceEventType? fromWireValue(String? wireValue) {
    if (wireValue == null) return null;
    for (final value in VoiceEventType.values) {
      if (value.wireValue == wireValue) return value;
    }
    return null;
  }
}

class VoiceEventMessage {
  final int version;
  final VoiceEventType? event;
  final String message;
  final String? code;
  final Map<String, dynamic>? data;

  VoiceEventMessage({
    required this.version,
    required this.event,
    required this.message,
    this.code,
    this.data,
  });

  factory VoiceEventMessage.fromJson(Map<String, dynamic> json) {
    return VoiceEventMessage(
      version: json['v'] is int ? (json['v'] as int) : 1,
      event: VoiceEventType.fromWireValue(json['event']?.toString()),
      message: json['message']?.toString() ?? '',
      code: json['code']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : (json['data'] is Map
                ? Map<String, dynamic>.from(json['data'] as Map)
                : null),
    );
  }
}

class VoiceControlMessage {
  final int version;
  final VoiceEventType event;

  const VoiceControlMessage(this.event, {this.version = 1});

  Map<String, dynamic> toJson() => {'v': version, 'event': event.wireValue};
}
