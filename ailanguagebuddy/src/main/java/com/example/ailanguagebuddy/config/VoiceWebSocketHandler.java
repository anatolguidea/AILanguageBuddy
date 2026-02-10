package com.example.ailanguagebuddy.config;

import com.example.ailanguagebuddy.service.ChatService;
import com.example.ailanguagebuddy.service.VoiceServiceClient;
import com.example.ailanguagebuddy.domain.AiTutorResult;
import com.example.ailanguagebuddy.domain.LearningContext;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class VoiceWebSocketHandler extends BinaryWebSocketHandler {

    private final VoiceServiceClient voiceService;
    private final ChatService chatService;
    private final com.example.ailanguagebuddy.repository.ChatMessageRepository chatMessageRepository;

    // Simplistic session tracking for demo purposes
    // In production, use a more robust session manager
    private final ConcurrentHashMap<String, StringBuilder> sessionTranscripts = new ConcurrentHashMap<>();

    public VoiceWebSocketHandler(VoiceServiceClient voiceService, ChatService chatService,
            com.example.ailanguagebuddy.repository.ChatMessageRepository chatMessageRepository) {
        this.voiceService = voiceService;
        this.chatService = chatService;
        this.chatMessageRepository = chatMessageRepository;
    }

    // Buffer to accumulate audio chunks
    private final ConcurrentHashMap<String, java.io.ByteArrayOutputStream> sessionAudioBuffers = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("Voice WS Connected: " + session.getId());

        // Extract userId from query params
        // Expected URI: /ws/voice?userId=...
        String query = session.getUri().getQuery();
        UUID userId = null;
        if (query != null && query.contains("userId=")) {
            String[] parts = query.split("userId=");
            if (parts.length > 1) {
                String idStr = parts[1].split("&")[0];
                try {
                    userId = UUID.fromString(idStr);
                    session.getAttributes().put("userId", userId);
                    System.out.println("User ID identified: " + userId);
                } catch (IllegalArgumentException e) {
                    System.err.println("Invalid User ID format: " + idStr);
                }
            }
        }

        if (userId == null) {
            System.err.println("Warning: No valid userId found in connection request.");
        }

        // Initialize buffer
        sessionAudioBuffers.put(session.getId(), new java.io.ByteArrayOutputStream());
        session.sendMessage(new TextMessage("CONNECTED"));
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) {
        // Just buffer the audio data. Do NOT process yet.
        try {
            java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(session.getId());
            if (buffer != null) {
                buffer.write(message.getPayload().array());
            }
        } catch (Exception e) {
            System.err.println("Error buffering audio: " + e.getMessage());
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        if ("EOS".equalsIgnoreCase(message.getPayload())) {
            processBufferedAudio(session);
        }
    }

    private void processBufferedAudio(WebSocketSession session) {
        try {
            java.io.ByteArrayOutputStream buffer = sessionAudioBuffers.get(session.getId());
            if (buffer == null || buffer.size() == 0) {
                return; // Nothing to process
            }

            byte[] completeAudio = buffer.toByteArray();
            // Reset buffer for next turn
            buffer.reset();

            System.out.println("Processing audio turn: " + completeAudio.length + " bytes");

            // 1. STT (Audio -> Text)
            // Call real Python STT (Whisper)
            String transcribedText = voiceService.transcribe(completeAudio);

            System.out.println("User said (STT): " + transcribedText);

            if (transcribedText == null || transcribedText.trim().isEmpty()) {
                session.sendMessage(new TextMessage("ERROR: No speech detected"));
                return;
            }

            // 2. LLM (Text -> Text)
            UUID userId = (UUID) session.getAttributes().get("userId");
            if (userId == null) {
                session.sendMessage(new TextMessage("ERROR: User ID missing"));
                return;
            }

            LearningContext context = new LearningContext("English", "A1", "General Conversation", "General");
            AiTutorResult aiResult = chatService.askLanguageCoach(transcribedText, userId, context);
            String aiReply = aiResult.replyText();
            System.out.println("AI Reply: " + aiReply);

            // 3. TTS (Text -> Voice)
            byte[] audioResponse = voiceService.synthesize(aiReply);

            // 4. Send Audio back to Client
            if (session.isOpen()) {
                session.sendMessage(new BinaryMessage(audioResponse));
            }
        } catch (Exception e) {
            System.err.println("Error processing voice turn: " + e.getMessage());
            e.printStackTrace();
            try {
                session.sendMessage(new TextMessage("ERROR: " + e.getMessage()));
            } catch (Exception ignored) {
            }
        }
    }
}
