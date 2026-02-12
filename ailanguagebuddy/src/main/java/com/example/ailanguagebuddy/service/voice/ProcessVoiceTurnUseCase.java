package com.example.ailanguagebuddy.service.voice;

import org.jspecify.annotations.Nullable;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.function.Consumer;

@Service
public class ProcessVoiceTurnUseCase {

    private final SpeechToTextPort speechToTextPort;
    private final TutorModelPort tutorModelPort;
    private final TextToSpeechPort textToSpeechPort;
    @Nullable
    private final StreamingTutorModelPort streamingTutorModelPort;

    public ProcessVoiceTurnUseCase(SpeechToTextPort speechToTextPort, TutorModelPort tutorModelPort,
            TextToSpeechPort textToSpeechPort,
            @Nullable StreamingTutorModelPort streamingTutorModelPort) {
        this.speechToTextPort = speechToTextPort;
        this.tutorModelPort = tutorModelPort;
        this.textToSpeechPort = textToSpeechPort;
        this.streamingTutorModelPort = streamingTutorModelPort;
    }

    /**
     * Whether the streaming pipeline is available.
     */
    public boolean isStreamingAvailable() {
        return streamingTutorModelPort != null;
    }

    /**
     * Streaming pipeline: STT (sync) → LLM streams sentences → callback fires per
     * sentence.
     * Returns the transcript + full reply text for persistence.
     */
    public TurnTextResult executeStreaming(byte[] audioBytes, UUID userId, Consumer<String> onSentence) {
        if (streamingTutorModelPort == null) {
            throw new VoiceTurnException("streaming_unavailable", "Streaming port not configured");
        }
        if (audioBytes == null || audioBytes.length == 0) {
            throw new VoiceTurnException("empty_audio", "No audio bytes received");
        }
        if (userId == null) {
            throw new VoiceTurnException("auth_failed", "Authenticated user is missing");
        }

        // Step 1: STT (blocking — typically fast via Groq/Whisper)
        String transcript = speechToTextPort.transcribe(audioBytes);
        if (transcript == null || transcript.trim().isEmpty()) {
            throw new VoiceTurnException("empty_transcript", "No speech detected");
        }

        // Step 2: Stream LLM → fires onSentence per completed sentence
        String fullReply = streamingTutorModelPort.streamReply(transcript, userId, onSentence);
        if (fullReply == null || fullReply.trim().isEmpty()) {
            throw new VoiceTurnException("model_failed", "AI model returned an empty response");
        }

        return new TurnTextResult(transcript, fullReply);
    }

    public VoiceTurnResult execute(byte[] audioBytes, UUID userId) {
        TurnTextResult textResult = executeTextOnly(audioBytes, userId);
        byte[] audioReply = textToSpeechPort.synthesize(textResult.replyText());
        if (audioReply == null || audioReply.length == 0) {
            throw new VoiceTurnException("tts_failed", "TTS returned an empty audio response");
        }
        return new VoiceTurnResult(textResult.transcript(), textResult.replyText(), audioReply);
    }

    public TurnTextResult executeTextOnly(byte[] audioBytes, UUID userId) {
        if (audioBytes == null || audioBytes.length == 0) {
            throw new VoiceTurnException("empty_audio", "No audio bytes received");
        }
        if (userId == null) {
            throw new VoiceTurnException("auth_failed", "Authenticated user is missing");
        }

        String transcript = speechToTextPort.transcribe(audioBytes);
        if (transcript == null || transcript.trim().isEmpty()) {
            throw new VoiceTurnException("empty_transcript", "No speech detected");
        }

        String aiReply = tutorModelPort.generateReply(transcript, userId);
        if (aiReply == null || aiReply.trim().isEmpty()) {
            throw new VoiceTurnException("model_failed", "AI model returned an empty response");
        }

        return new TurnTextResult(transcript, aiReply);
    }

    public record TurnTextResult(String transcript, String replyText) {
    }

    public record VoiceTurnResult(String transcript, String replyText, byte[] replyAudio) {
    }
}
