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
    String safeHistory = (historyFromSupabase == null || historyFromSupabase.isBlank()) ? "(no prior history)"
        : historyFromSupabase;
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
        - Keep the response SHORT and SPOKEN (max 20 words).
        - Use simple language suitable for a beginner/intermediate learner.
        - If the user corrects you, acknowledge it and continue.
        - Respond ONLY with the spoken reply in the target language.
        - Do NOT help with grammar or vocabulary lists.
        - Do NOT use JSON. Just plain text.
        """.formatted(safeHistory, safeCurrent, target, nativeLang, level, scenario.getTitle(), liveVoiceInstruction);
  }

  private static String orDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value;
  }
}
