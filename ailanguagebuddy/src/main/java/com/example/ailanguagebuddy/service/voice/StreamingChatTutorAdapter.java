package com.example.ailanguagebuddy.service.voice;

import com.example.ailanguagebuddy.domain.LearningContext;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.regex.Pattern;

/**
 * Streaming adapter for the voice pipeline.
 * <p>
 * Uses {@link ChatModel#stream(Prompt)} to receive LLM tokens incrementally.
 * Accumulates tokens into a buffer and emits complete sentences via the
 * {@code onSentence} callback as soon as a sentence boundary is detected.
 * <p>
 * Unlike the regular {@link ChatTutorAdapter}, this adapter uses a
 * <b>plain-text system prompt</b> (no JSON) so that sentence boundaries
 * can be detected on-the-fly without waiting for the full JSON to parse.
 */
@Component
public class StreamingChatTutorAdapter implements StreamingTutorModelPort {

    private static final int MAX_VOICE_REPLY_SENTENCES = 1;
    private static final int MAX_VOICE_REPLY_CHARS = 220;
    private static final int MAX_VOICE_REPLY_WORDS = 15;
    private static final Pattern SENTENCE_END = Pattern.compile("(?<=[.!?])\\s+");

    private final ChatModel chatModel;

    public StreamingChatTutorAdapter(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    @Override
    public String streamReply(String userText, UUID userId, Consumer<String> onSentence) {
        LearningContext context = new LearningContext("English", "A1", "General Conversation", "General");

        // Voice-optimized system prompt: plain text, short answer, no JSON.
        String systemPrompt = buildVoiceSystemPrompt(context);
        Prompt prompt = new Prompt(List.of(
                new SystemMessage(systemPrompt),
                new UserMessage(userText)));

        StringBuilder fullReply = new StringBuilder();
        StringBuilder sentenceBuffer = new StringBuilder();
        int sentencesEmitted = 0;

        // Blocking subscribe — we're on the WS handler thread which is already
        // off the event loop, so blocking is fine and keeps the architecture simple.
        var flux = chatModel.stream(prompt);
        var iterable = flux.toIterable();

        for (var chatResponse : iterable) {
            String token = chatResponse.getResult() != null
                    ? chatResponse.getResult().getOutput().getText()
                    : null;
            if (token == null || token.isEmpty()) {
                continue;
            }

            fullReply.append(token);
            sentenceBuffer.append(token);

            // Check if we've accumulated a complete sentence
            String buffered = sentenceBuffer.toString();
            String[] parts = SENTENCE_END.split(buffered, -1);

            // If there are 2+ parts, the first N-1 are complete sentences
            if (parts.length > 1) {
                for (int i = 0; i < parts.length - 1; i++) {
                    String sentence = parts[i].trim();
                    if (sentence.isEmpty()) {
                        continue;
                    }
                    if (sentencesEmitted >= MAX_VOICE_REPLY_SENTENCES) {
                        break;
                    }
                    int projectedChars = currentCharsEmitted(sentencesEmitted, sentence);
                    if (projectedChars > MAX_VOICE_REPLY_CHARS && sentencesEmitted > 0) {
                        break;
                    }
                    onSentence.accept(applyConciseRules(sentence));
                    sentencesEmitted++;
                }
                // Keep the last (incomplete) part in the buffer
                sentenceBuffer.setLength(0);
                sentenceBuffer.append(parts[parts.length - 1]);

                if (sentencesEmitted >= MAX_VOICE_REPLY_SENTENCES) {
                    break; // stop consuming tokens early
                }
            }
        }

        // Flush remaining buffer if under limits
        String remaining = sentenceBuffer.toString().trim();
        if (!remaining.isEmpty() && sentencesEmitted < MAX_VOICE_REPLY_SENTENCES) {
            int projectedChars = currentCharsEmitted(sentencesEmitted, remaining);
            if (projectedChars <= MAX_VOICE_REPLY_CHARS || sentencesEmitted == 0) {
                onSentence.accept(applyConciseRules(remaining));
            }
        }

        return applyConciseRules(fullReply.toString());
    }

    private int currentCharsEmitted(int count, String next) {
        // Rough estimate: each previous sentence averages ~80 chars
        return (count * 80) + next.length();
    }

    private String applyConciseRules(String text) {
        if (text == null || text.isBlank()) {
            return "";
        }
        String[] words = text.trim().split("\\s+");
        int limit = Math.min(words.length, MAX_VOICE_REPLY_WORDS);
        String compact = String.join(" ", java.util.Arrays.copyOfRange(words, 0, limit)).trim();
        if (compact.isEmpty()) {
            return "";
        }
        int questionCount = 0;
        StringBuilder cleaned = new StringBuilder(compact.length());
        for (int i = 0; i < compact.length(); i++) {
            char c = compact.charAt(i);
            if (c == '?') {
                questionCount++;
                cleaned.append(questionCount > 1 ? '.' : '?');
            } else {
                cleaned.append(c);
            }
        }
        return cleaned.toString().trim();
    }

    /**
     * Voice-specific system prompt: plain text only, no JSON, keep it short.
     */
    private String buildVoiceSystemPrompt(LearningContext context) {
        return """
                You are a friendly language tutor having a spoken conversation.
                The learner is studying %s at level %s.

                Rules for your response:
                - You are a concise English tutor. Respond in 10-15 words max.
                - Avoid asking multiple questions in one turn.
                - Reply in %s (the target language) with one short sentence.
                - Be warm, encouraging and natural, as if speaking aloud.
                - If the learner makes a mistake, gently correct it within your reply.
                - Do NOT use JSON, markdown, or any formatting. Plain spoken text only.
                - Keep your entire response under 200 characters.
                """.formatted(
                context.targetLanguage(),
                context.level(),
                context.targetLanguage());
    }
}
