package com.example.ailanguagebuddy.service.voice;

import java.util.UUID;
import java.util.function.Consumer;

/**
 * Streaming variant of {@link TutorModelPort}.
 * <p>
 * Instead of blocking until the full reply is ready, this port emits
 * complete sentences one-by-one via the {@code onSentence} callback.
 * The caller can start TTS on each sentence immediately, achieving
 * pipelined LLM → TTS execution.
 * </p>
 */
public interface StreamingTutorModelPort {

    /**
     * Stream LLM sentences for the given user text.
     *
     * @param userText   the transcribed user input
     * @param userId     authenticated user id
     * @param onSentence callback invoked with each complete sentence as it arrives
     * @return the full concatenated reply text (for persistence and fallback)
     */
    String streamReply(String userText, UUID userId, Consumer<String> onSentence);
}
