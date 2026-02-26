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
import java.util.ArrayList;
import java.util.List;

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

    /** In-memory conversation history per voice session. Cleared when the WebSocket closes (screen closed). */
    private static final int VOICE_HISTORY_LIMIT = 10; // max exchanges (user + assistant = 2 lines each)
    private final ConcurrentHashMap<String, List<String>> sessionVoiceHistory = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("Voice WS Connected: " + session.getId());

        // Extract userId and targetLanguage from query params
        // Expected URI: /ws/voice?userId=...&targetLanguage=es
        String query = session.getUri().getQuery();
        UUID userId = null;
        String targetLanguageCode = "en";
        // Always store normalized code so LLM and TTS use the same language
        if (query != null) {
            for (String param : query.split("&")) {
                if (param.startsWith("userId=")) {
                    String idStr = param.substring(7).split("&")[0];
                    try {
                        userId = UUID.fromString(idStr);
                        session.getAttributes().put("userId", userId);
                        System.out.println("User ID identified: " + userId);
                    } catch (IllegalArgumentException e) {
                        System.err.println("Invalid User ID format: " + idStr);
                    }
                } else if (param.startsWith("targetLanguage=")) {
                    String raw = param.substring(14).split("&")[0].trim();
                    if (raw.isEmpty()) raw = "en";
                    targetLanguageCode = normalizeLanguageCode(raw);
                    session.getAttributes().put("targetLanguageCode", targetLanguageCode);
                }
            }
        }
        session.getAttributes().put("targetLanguageCode", targetLanguageCode);

        if (userId == null) {
            System.err.println("Warning: No valid userId found in connection request.");
        }

        // Initialize buffer
        sessionAudioBuffers.put(session.getId(), new java.io.ByteArrayOutputStream());
        sessionVoiceHistory.put(session.getId(), new ArrayList<>());
        session.sendMessage(new TextMessage("CONNECTED"));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
        // User left the voice screen: clear session history so next time they open voice they start fresh
        sessionAudioBuffers.remove(session.getId());
        sessionVoiceHistory.remove(session.getId());
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

            UUID userId = (UUID) session.getAttributes().get("userId");
            if (userId == null) {
                session.sendMessage(new TextMessage("ERROR: User ID missing"));
                return;
            }

            String targetLanguageCode = normalizeLanguageCode(
                    (String) session.getAttributes().getOrDefault("targetLanguageCode", "en"));
            System.out.println("Voice session language: " + targetLanguageCode);

            // 1. STT (Audio -> Text) in the target language
            String transcribedText = voiceService.transcribe(completeAudio, targetLanguageCode);

            System.out.println("User said (STT): " + transcribedText);

            if (transcribedText == null || transcribedText.trim().isEmpty()) {
                session.sendMessage(new TextMessage("ERROR: No speech detected"));
                return;
            }

            // 2. LLM (Text -> Text)
            // Use same LearningContext shape as chat (mode=general) so the LLM gets the exact same prompt as chat messages
            LearningContext context = new LearningContext(
                    toDisplayName(targetLanguageCode),
                    "English",
                    "A1",
                    "general",
                    "en");
            // Use in-memory session history only (cleared when socket closes)
            String voiceHistoryBlock = buildSessionHistoryBlock(session.getId());
            AiTutorResult aiResult = chatService.askLanguageCoach(transcribedText, userId, context, voiceHistoryBlock);
            // Only the reply is sent to TTS (not corrections or tips)
            String aiReply = aiResult.replyText();
            System.out.println("AI Reply: " + aiReply);

            // Append this turn to session history for next time (same session only)
            appendToSessionHistory(session.getId(), transcribedText, aiReply);

            // 3. Send AI text to client so UI can display it
            if (session.isOpen()) {
                session.sendMessage(new TextMessage("TEXT:" + aiReply));
            }

            // 4. TTS (Text -> Voice) with language for correct voice
            var instant = voiceService.synthesizeInstant(aiReply, targetLanguageCode);
            byte[] audioResponse = instant.audioBytes();

            // 5. Send Audio back to Client (format hint so client can use correct codec)
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(
                        "AUDIO:" + instant.codec() + "," + instant.sampleRate()));
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

    private static String toDisplayName(String code) {
        if (code == null || code.isEmpty()) return "English";
        return switch (code.toLowerCase()) {
            case "ro" -> "Romanian";
            case "es" -> "Spanish";
            case "fr" -> "French";
            case "de" -> "German";
            case "it" -> "Italian";
            case "pt" -> "Portuguese";
            case "ru" -> "Russian";
            case "ja" -> "Japanese";
            case "zh" -> "Chinese";
            case "ko" -> "Korean";
            default -> "English";
        };
    }

    private static String normalizeLanguageCode(String raw) {
        if (raw == null || raw.isBlank()) return "en";
        String v = raw.trim().toLowerCase();
        if (v.startsWith("=")) v = v.substring(1).trim();
        if ("e".equals(v)) return "en";
        if ("f".equals(v)) return "fr";
        if (v.length() >= 2) return v.split("-")[0];
        return "en";
    }

    private String buildSessionHistoryBlock(String sessionId) {
        List<String> lines = sessionVoiceHistory.get(sessionId);
        if (lines == null || lines.isEmpty()) return "";
        return String.join("\n", lines);
    }

    private void appendToSessionHistory(String sessionId, String userMessage, String assistantReply) {
        sessionVoiceHistory.compute(sessionId, (k, list) -> {
            if (list == null) list = new ArrayList<>();
            list.add("user: " + (userMessage != null ? userMessage.replace("\n", " ").trim() : ""));
            list.add("assistant: " + (assistantReply != null ? assistantReply.replace("\n", " ").trim() : ""));
            // Keep only last N exchanges (2 lines each)
            while (list.size() > VOICE_HISTORY_LIMIT * 2) {
                list.remove(0);
            }
            return list;
        });
    }
}
