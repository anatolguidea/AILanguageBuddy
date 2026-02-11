package com.example.ailanguagebuddy.service.voice;

import com.example.ailanguagebuddy.domain.AiTutorResult;
import com.example.ailanguagebuddy.domain.LearningContext;
import com.example.ailanguagebuddy.service.ChatService;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class ChatTutorAdapter implements TutorModelPort {
    private static final int MAX_VOICE_REPLY_SENTENCES = 2;
    private static final int MAX_VOICE_REPLY_CHARS = 220;
    private final ChatService chatService;

    public ChatTutorAdapter(ChatService chatService) {
        this.chatService = chatService;
    }

    @Override
    public String generateReply(String userText, UUID userId) {
        LearningContext context = new LearningContext("English", "A1", "General Conversation", "General");
        AiTutorResult aiResult = chatService.askLanguageCoach(userText, userId, context);
        return shortenForVoice(aiResult.replyText());
    }

    private String shortenForVoice(String replyText) {
        if (replyText == null) {
            return "";
        }
        String normalized = replyText.trim();
        if (normalized.isEmpty()) {
            return "";
        }
        String[] sentences = normalized.split("(?<=[.!?])\\s+");
        StringBuilder compact = new StringBuilder();
        int sentenceCount = 0;
        for (String sentence : sentences) {
            String s = sentence.trim();
            if (s.isEmpty()) {
                continue;
            }
            int projectedLength = compact.length() + (compact.length() == 0 ? 0 : 1) + s.length();
            if (sentenceCount >= MAX_VOICE_REPLY_SENTENCES || projectedLength > MAX_VOICE_REPLY_CHARS) {
                break;
            }
            if (compact.length() > 0) {
                compact.append(' ');
            }
            compact.append(s);
            sentenceCount++;
        }
        if (compact.length() == 0) {
            return normalized.length() <= MAX_VOICE_REPLY_CHARS
                    ? normalized
                    : normalized.substring(0, MAX_VOICE_REPLY_CHARS).trim();
        }
        return compact.toString();
    }
}
