package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.model.ChatMessage;
import com.example.ailanguagebuddy.repository.ChatMessageRepository;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Collections;
import java.util.UUID;

@Service
public class ChatService {

    private final ChatModel chatModel;
    private final ChatMessageRepository repository;

    public ChatService(ChatModel chatModel, ChatMessageRepository repository) {
        this.chatModel = chatModel;
        this.repository = repository;
    }

    /**
     * Sends the message to Groq and persists user/assistant messages for the given user.
     */
    public String askLanguageCoach(String userMessage, UUID userId) {
        var systemInstructions = new SystemMessage("Ești un profesor de limbi străine prietenos și experimentat. " +
                "Corectezi greșelile gramaticale, răspunzi politicos în limba primită și dai o singură explicație scurtă când corectezi.");
        var userMsg = new UserMessage(userMessage);
        Prompt prompt = new Prompt(List.of(systemInstructions, userMsg));

        try {
            repository.save(new ChatMessage(userMessage, "user", userId));

            String aiResponse = chatModel.call(prompt)
                    .getResult()
                    .getOutput()
                    .getText();

            repository.save(new ChatMessage(aiResponse, "assistant", userId));
            return aiResponse;
        } catch (Exception e) {
            return "Eroare AI: " + e.getMessage();
        }
    }

    public List<ChatMessage> loadHistory(UUID userId, int limit) {
        var items = repository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, limit));
        Collections.reverse(items);
        return items;
    }
}
