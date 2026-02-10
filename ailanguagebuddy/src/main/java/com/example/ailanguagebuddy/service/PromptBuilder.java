package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.domain.LearningContext;
import org.springframework.stereotype.Component;

@Component
public class PromptBuilder {

  public String buildSystemPrompt(LearningContext ctx) {
    var effective = ctx != null ? ctx : LearningContext.defaultChat();
    String target = orDefault(effective.targetLanguage(), "the target language");
    String nativeLang = orDefault(effective.nativeLanguage(), "the learner's native language");
    String level = orDefault(effective.level(), "B1");
    String mode = orDefault(effective.mode(), "general");
    com.example.ailanguagebuddy.domain.Scenario scenario = com.example.ailanguagebuddy.domain.Scenario.fromId(mode);

    return """
        %s
        The learner's target language is %s, their native language is %s, and their approximate level is %s.
        Current context: %s.

        For each user message:
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
        """.formatted(scenario.getInstructions(), target, nativeLang, level, scenario.getTitle());
  }

  private static String orDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value;
  }
}
