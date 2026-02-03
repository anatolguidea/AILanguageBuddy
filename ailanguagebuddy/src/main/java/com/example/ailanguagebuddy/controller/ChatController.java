package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    private final ChatService chatService;

    // Constructor manual (înlocuiește @RequiredArgsConstructor)
    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/ask")
    public ResponseEntity<String> ask(@RequestBody String message) {
        String response = chatService.askLanguageCoach(message);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/history")
    public ResponseEntity<?> history(@RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(chatService.loadHistory(limit));
    }
}
