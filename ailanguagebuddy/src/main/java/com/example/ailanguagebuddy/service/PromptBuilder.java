package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.config.TopicConfigService;
import com.example.ailanguagebuddy.domain.LearningContext;
import org.springframework.stereotype.Component;

@Component
public class PromptBuilder {

    private final TopicConfigService topicConfigService;

    public PromptBuilder(TopicConfigService topicConfigService) {
        this.topicConfigService = topicConfigService;
    }

    public String buildSystemPrompt(LearningContext ctx) {
        return buildSystemPrompt(ctx, "", "");
    }

    public String buildSystemPrompt(LearningContext ctx, String historyFromSupabase, String currentMessage) {
        var effective = ctx != null ? ctx : LearningContext.defaultChat();
        String target = orDefault(effective.targetLanguage(), "the target language");
        String nativeLang = orDefault(effective.nativeLanguage(), "the learner's native language");
        String level = orDefault(effective.level(), "B1");
        String mode = orDefault(effective.mode(), "general");
        boolean instructionRo = effective.instructionLocale() != null && effective.instructionLocale().toLowerCase().startsWith("ro");

        String topicInstruction = topicConfigService.getTopic(mode)
                .map(t -> t.instruction())
                .orElse("You are a supportive language tutor. Have a natural conversation.");
        String topicsBlock = topicConfigService.getTopicsContextBlock();
        String safeHistory = (historyFromSupabase == null || historyFromSupabase.isBlank()) ? "(no prior history)"
                : historyFromSupabase;
        String safeCurrent = (currentMessage == null || currentMessage.isBlank()) ? "(empty input)" : currentMessage;
        String liveVoiceInstruction = "VOICE_LIVE".equalsIgnoreCase(mode)
                ? "You are currently in LIVE VOICE mode. Your context is limited to the current vocal exchange."
                : "";
        String instructionLanguageRule = instructionRo
                ? "The learner's app is in Romanian. Write the \"correction\" and \"tips\" fields in Romanian (e.g. explain grammar/vocabulary in Romanian). Use Romanian for any meta-instructions."
                : "";

        return """
            Role: You are a supportive language tutor named Sarah. You correct gently and give brief tips.

            Available topics (current conversation topic: %s):
            %s
            Current topic instruction: %s

            Conversation History:
            %s

            Current User Input:
            %s

            Learner profile:
            - Target language: %s
            - Native language: %s
            - Approximate level: %s

            Instructions:
            - %s
            - Use the history to resolve pronouns.
            - Keep your spoken reply SHORT and natural (max 25 words).
            - If the user made grammar/vocabulary mistakes, provide the corrected version and a brief tip.
            - Respond ONLY with valid JSON in this exact format (no markdown, no extra text):
            {"reply": "your spoken reply in the target language", "correction": "corrected version of user's last message or empty string if no errors", "tips": "brief grammar or vocabulary tip or empty string"}

            - "correction" must be the full corrected sentence of the user's last message, or "" if no correction needed.
            - "tips" must be one short sentence (e.g. Use "went" for past tense of "go"). Use double quotes for examples; avoid backslash-escaping. Use "" if no tip.
            %s
            """.formatted(mode, topicsBlock, topicInstruction, safeHistory, safeCurrent, target, nativeLang, level, liveVoiceInstruction,
                    instructionLanguageRule.isBlank() ? "" : "\n" + instructionLanguageRule);
    }

    /** Prompt for generating the first message when the user opens a topic with no history. */
    public String buildInitialGreetingPrompt(LearningContext ctx, String historyBlock) {
        var effective = ctx != null ? ctx : LearningContext.defaultChat();
        String target = orDefault(effective.targetLanguage(), "the target language");
        String nativeLang = orDefault(effective.nativeLanguage(), "the learner's native language");
        String level = orDefault(effective.level(), "B1");
        String mode = orDefault(effective.mode(), "general");

        String topicInstruction = topicConfigService.getTopic(mode)
                .map(t -> t.instruction())
                .orElse("You are a supportive language tutor.");

        return """
            Role: You are a supportive language tutor named Sarah. Start the conversation for this topic.

            Topic: %s. Context: %s

            Learner: target language=%s (REPLY ONLY IN THIS LANGUAGE), native=%s (do NOT use this in your reply), level=%s.

            There is no prior history. Write a short, friendly first message to start the conversation (e.g. ask a question or suggest something to talk about). Keep it under 20 words and spoken-style. Your entire reply MUST be in the target language (%s) only.

            Respond ONLY with valid JSON: {"reply": "your first message in target language", "correction": "", "tips": ""}
            """.formatted(mode, topicInstruction, target, nativeLang, level, target);
    }

    private static String orDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
