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

@Service
public class ChatService {

    private final ChatModel chatModel;
    private final ChatMessageRepository repository;

    public ChatService(ChatModel chatModel, ChatMessageRepository repository) {
        this.chatModel = chatModel;
        this.repository = repository;
    }

    /**
     * Trimite mesajul către Groq folosind un System Prompt pentru a ghida comportamentul AI-ului.
     */
    public String askLanguageCoach(String userMessage) {
        var systemInstructions = new SystemMessage("Ești un profesor de limbi străine prietenos și experimentat. " +
                "Corectezi greșelile gramaticale, răspunzi politicos în limba primită și dai o singură explicație scurtă când corectezi.");
        var userMsg = new UserMessage(userMessage);
        Prompt prompt = new Prompt(List.of(systemInstructions, userMsg));

        try {
            repository.save(new ChatMessage(userMessage, "user"));

            String aiResponse = chatModel.call(prompt)
                    .getResult()
                    .getOutput()
                    .getText();

            repository.save(new ChatMessage(aiResponse, "assistant"));
            return aiResponse;
        } catch (Exception e) {
            return "Eroare AI: " + e.getMessage();
        }
    }

    public List<ChatMessage> loadHistory(int limit) {
        var items = repository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, limit));
        Collections.reverse(items);
        return items;
    }
}
