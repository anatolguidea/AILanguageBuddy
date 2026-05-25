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
        String topicId = normalizeTopicMode(mode);
        boolean instructionRo = effective.instructionLocale() != null && effective.instructionLocale().toLowerCase().startsWith("ro");

        String topicInstruction = topicConfigService.getTopic(topicId)
                .map(t -> t.instruction())
                .orElse("You are a supportive language tutor. Have a natural conversation.");
        String topicsBlock = topicConfigService.getTopicsContextBlock();
        String safeHistory = (historyFromSupabase == null || historyFromSupabase.isBlank()) ? "(no prior history)"
                : historyFromSupabase;
        String safeCurrent = (currentMessage == null || currentMessage.isBlank())
                ? "(empty input)"
                : sanitizeForPrompt(currentMessage);
        String liveVoiceInstruction = "VOICE_LIVE".equalsIgnoreCase(mode)
                ? ("You are in LIVE VOICE mode. The user is speaking in " + target + ". You MUST reply ONLY in " + target + ". Do not reply in English unless the target language is English. Example: if target is French and the user says 'Bonjour', reply in French (e.g. 'Bonjour ! Comment allez-vous ?'), never in English.")
                : "";
        // For voice mode, prepend an unambiguous output-language line so the model cannot miss it.
        String outputLanguageBanner = "VOICE_LIVE".equalsIgnoreCase(mode)
                ? ("OUTPUT_LANGUAGE: " + target + ". Your \"reply\" field must be written entirely in " + target + ". Do not use English unless the target is English.\n\n")
                : "";
        String instructionLanguageRule = instructionRo
                ? "The learner's app is in Romanian. Write the \"correction\" and \"tips\" fields in Romanian (e.g. explain grammar/vocabulary in Romanian). Use Romanian for any meta-instructions."
                : "";

        return outputLanguageBanner + """
            Role: You are Sarah, a warm and encouraging language tutor. You correct gently, give brief tips, and keep the conversation going like a supportive teacher. Sound natural but a bit more expansive than one-line answers.

            CRITICAL - Language consistency: If the target language is English, you MUST respond ONLY in English. Do not use words from other languages (e.g. do not say "Bonjour", "Hola", "Ciao") in your reply unless the user explicitly asks for a translation. If the target language is French, reply ONLY in French. Same for any other target language: your entire "reply" must be in that language only.

            Available topics (current conversation topic: %s):
            %s
            Current topic instruction: %s

            Conversation History:
            %s

            Current User Input (reply in %s):
            %s

            Learner profile:
            - Target language: %s
            - Native language: %s
            - Approximate level: %s

            Instructions:
            - %s
            - Use the history to resolve pronouns.
            - Reply in a tutor style: acknowledge what they said, add a short encouraging or clarifying sentence, and optionally ask a follow-up question or suggest something to talk about. Aim for 2–4 sentences (about 40–55 words). Keep it natural and conversational, not robotic.
            - Grammar correction policy: evaluate ONLY the Current User Input. Preserve the user's meaning. Correct grammar, word choice, spelling, and target-language phrasing only when there is a clear learner mistake. Do not rewrite for style. If the input is already acceptable, return "" for "correction", "" for "tips", and [] for "corrections".
            - If there is one clear mistake, set "correction" to the full corrected version of the user's last message and "tips" to one short explanation. If there are multiple mistakes, also include each one in "corrections".
            - Include a translation only when useful for the learner's native language; otherwise use an empty string.
            - Respond ONLY with valid JSON in this exact format (no markdown, no extra text):
            {"reply": "your spoken reply in the target language", "translation": "translation of reply in native language or empty string", "correction": "full corrected version of user's last message or empty string if no errors", "tips": "brief grammar or vocabulary tip or empty string", "corrections": [{"original": "exact mistaken text", "corrected": "corrected text", "explanation": "why this is better"}]}

            - "reply" must be ONLY in the target language (%s). Do not mix languages. For voice mode, never reply in English when the target is another language.
            - "translation" should be in %s only when it helps comprehension. If not needed, return "".
            - "correction" must be the full corrected sentence of the user's last message, or "" if no correction needed.
            - "tips" must be one short sentence explaining the correction. Use double quotes for examples; avoid backslash-escaping. Use "" if no tip.
            - "corrections" must be [] if no correction is needed. Never put the same text in "original" and "corrected".
            %s
            """.formatted(topicId, topicsBlock, topicInstruction, safeHistory, target, safeCurrent, target, nativeLang, level, liveVoiceInstruction,
                    target, nativeLang, instructionLanguageRule.isBlank() ? "" : "\n" + instructionLanguageRule);
    }

    /** Prompt for generating the first message when the user opens a topic with no history. */
    public String buildInitialGreetingPrompt(LearningContext ctx, String historyBlock) {
        var effective = ctx != null ? ctx : LearningContext.defaultChat();
        String target = orDefault(effective.targetLanguage(), "the target language");
        String nativeLang = orDefault(effective.nativeLanguage(), "the learner's native language");
        String level = orDefault(effective.level(), "B1");
        String mode = normalizeTopicMode(orDefault(effective.mode(), "general"));

        String topicInstruction = topicConfigService.getTopic(mode)
                .map(t -> t.instruction())
                .orElse("You are a supportive language tutor.");

        return """
            Role: You are Sarah, a warm and encouraging language tutor. Start the conversation in a friendly, tutor-like way.

            CRITICAL: Reply ONLY in the target language. Do not mix in words from other languages (e.g. no "Bonjour" in an English reply).

            Topic: %s. Context: %s

            Learner: target language=%s (REPLY ONLY IN THIS LANGUAGE), native=%s (do NOT use this in your reply), level=%s.

            There is no prior history. Write a friendly first message as a tutor would: greet them, briefly say what you can do together for this topic, and ask a first question or suggest something to try. Use 2–3 sentences (about 30–45 words). Warm and inviting, not one-line. Your entire reply MUST be in the target language (%s) only.

            Respond ONLY with valid JSON: {"reply": "your first message in target language", "translation": "", "correction": "", "tips": ""}
            """.formatted(mode, topicInstruction, target, nativeLang, level, target);
    }

    private static String orDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private static String normalizeTopicMode(String mode) {
        if (mode == null || mode.isBlank()) {
            return "general";
        }
        return mode.trim().replaceFirst("_(en|ro|es|fr|de|it|pt|ru|ja|zh)$", "");
    }

    /**
     * Strips characters that could enable prompt injection before embedding user
     * input into the system prompt template. Newlines are collapsed so the user
     * cannot inject new prompt sections; triple-backticks and role-override markers
     * are removed.
     */
    private static String sanitizeForPrompt(String input) {
        if (input == null) return "(empty input)";
        return input
                .replace("\r\n", " ")
                .replace("\n", " ")
                .replace("\r", " ")
                .replace("```", "")
                .replace("###", "")
                .trim();
    }
}
