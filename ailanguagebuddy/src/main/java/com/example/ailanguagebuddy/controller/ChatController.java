package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/ask")
    public ResponseEntity<String> ask(
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestBody String message) {
        UUID userUuid = parseUserId(userId);
        if (userUuid == null) {
            return ResponseEntity.status(401).body("Missing or invalid X-User-Id header (must be a UUID)");
        }
        String response = chatService.askLanguageCoach(message, userUuid);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/history")
    public ResponseEntity<?> history(
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestParam(defaultValue = "50") int limit) {
        UUID userUuid = parseUserId(userId);
        if (userUuid == null) {
            return ResponseEntity.status(401).body("Missing or invalid X-User-Id header (must be a UUID)");
        }
        return ResponseEntity.ok(chatService.loadHistory(userUuid, limit));
    }

    private static UUID parseUserId(String userId) {
        if (userId == null || userId.isBlank()) return null;
        try {
            return UUID.fromString(userId.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
