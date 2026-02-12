package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.domain.LearningContext;
import org.springframework.stereotype.Component;

@Component
public class PromptBuilder {

  public String buildSystemPrompt(LearningContext ctx) {
    return buildSystemPrompt(ctx, "", "");
  }

  public String buildSystemPrompt(LearningContext ctx, String historyFromSupabase, String currentMessage) {
    var effective = ctx != null ? ctx : LearningContext.defaultChat();
    String target = orDefault(effective.targetLanguage(), "the target language");
    String nativeLang = orDefault(effective.nativeLanguage(), "the learner's native language");
    String level = orDefault(effective.level(), "B1");
    String mode = orDefault(effective.mode(), "general");
    com.example.ailanguagebuddy.domain.Scenario scenario = com.example.ailanguagebuddy.domain.Scenario.fromId(mode);
    String safeHistory = (historyFromSupabase == null || historyFromSupabase.isBlank()) ? "(no prior history)" : historyFromSupabase;
    String safeCurrent = (currentMessage == null || currentMessage.isBlank()) ? "(empty input)" : currentMessage;
    String liveVoiceInstruction = "VOICE_LIVE".equalsIgnoreCase(mode)
        ? "You are currently in LIVE VOICE mode. Your context is limited to the current vocal exchange."
        : "";

    return """
        Role: You are a helpful and concise English Tutor named Sarah.

        Conversation History:
        %s

        Current User Input:
        %s

        Learner profile:
        - Target language: %s
        - Native language: %s
        - Approximate level: %s
        - Scenario context: %s

        Instructions:
        - %s
        - Use the history to resolve pronouns like "it", "that", or "them".
        - Keep the response under 15 words to maintain low latency for TTS.
        - If the user corrects you, acknowledge it and continue the lesson.
        - Correct grammar, vocabulary and naturalness.
        - Keep the reply in the target language unless explicitly asked otherwise.
        - Explain corrections briefly and clearly, in the learner's native language when helpful.

        Respond ONLY with valid JSON (no markdown, no extra text) with this shape:
        {
          "replyText": "your corrected answer and guidance in the target language",
          "corrections": [
            {
              "original": "the learner's original fragment",
              "corrected": "the improved version",
              "explanation": "short explanation of what changed and why"
            }
          ],
          "vocabulary": [
            {
              "term": "useful word or expression",
              "translation": "short translation in the learner's native language",
              "note": "optional nuance or usage note"
            }
          ]
        }
        """.formatted(safeHistory, safeCurrent, target, nativeLang, level, scenario.getTitle(), liveVoiceInstruction);
  }

  private static String orDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value;
  }
}
