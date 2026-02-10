package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.api.dto.ChatAskRequest;
import com.example.ailanguagebuddy.api.dto.ChatAskResponse;
import com.example.ailanguagebuddy.api.dto.ChatMessageDto;
import com.example.ailanguagebuddy.api.dto.ChatHistoryResponse;
import com.example.ailanguagebuddy.api.dto.CorrectionDto;
import com.example.ailanguagebuddy.api.dto.VocabularyItemDto;
import com.example.ailanguagebuddy.security.AuthUserResolver;
import com.example.ailanguagebuddy.service.ChatService;
import com.example.ailanguagebuddy.domain.LearningContext;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

        private final ChatService chatService;
        private final AuthUserResolver authUserResolver;

        public ChatController(ChatService chatService, AuthUserResolver authUserResolver) {
                this.chatService = chatService;
                this.authUserResolver = authUserResolver;
        }

        @PostMapping("/ask")
        public ResponseEntity<ChatAskResponse> ask(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody ChatAskRequest request) {
                var user = authUserResolver.fromJwt(jwt);
                System.out.println(">>> DEBUG: /ask called by User: " + user.userId());

                var ctx = new LearningContext(
                                request.targetLanguage(),
                                request.nativeLanguage(),
                                request.level(),
                                request.mode());
                var result = chatService.askLanguageCoach(request.message(), user.userId(), ctx);
                var correctionsDto = result.corrections().stream()
                                .map(c -> new CorrectionDto(c.original(), c.corrected(), c.explanation()))
                                .toList();
                var vocabDto = result.vocabulary().stream()
                                .map(v -> new VocabularyItemDto(v.term(), v.translation(), v.note()))
                                .toList();
                return ResponseEntity.ok(new ChatAskResponse(result.replyText(), correctionsDto, vocabDto));
        }

        @GetMapping("/history")
        public ResponseEntity<List<ChatMessageDto>> history(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestParam(defaultValue = "50") int limit,
                        @RequestParam(defaultValue = "general") String mode) {
                var user = authUserResolver.fromJwt(jwt);
                var items = chatService.loadHistory(user.userId(), mode, limit).stream()
                                .map(m -> new ChatMessageDto(
                                                m.getId(),
                                                m.getContent(),
                                                m.getRole(),
                                                m.getCreatedAt(),
                                                m.getUserId()))
                                .toList();
                return ResponseEntity.ok(items);
        }

        @GetMapping("/history/v2")
        public ResponseEntity<ChatHistoryResponse> historyV2(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestParam(defaultValue = "50") int limit,
                        @RequestParam(name = "cursor", required = false) String cursor,
                        @RequestParam(defaultValue = "general") String mode) {
                var user = authUserResolver.fromJwt(jwt);
                System.out.println(">>> DEBUG: /history/v2 called by User: " + user.userId() + " Mode: " + mode);

                LocalDateTime before = null;
                if (cursor != null && !cursor.isBlank()) {
                        try {
                                before = LocalDateTime.parse(cursor);
                        } catch (DateTimeParseException e) {
                                throw new IllegalArgumentException(
                                                "Invalid cursor format, expected ISO-8601 timestamp");
                        }
                }

                var raw = chatService.loadHistoryPage(user.userId(), mode, limit, before);
                System.out.println(">>> DEBUG: Found " + raw.size() + " messages for User: " + user.userId());

                boolean hasMore = raw.size() > limit;
                var pageItems = hasMore ? raw.subList(0, limit) : raw;

                // reverse for chronological order (oldest first)
                var items = pageItems.stream()
                                .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                                .map(m -> new ChatMessageDto(
                                                m.getId(),
                                                m.getContent(),
                                                m.getRole(),
                                                m.getCreatedAt(),
                                                m.getUserId()))
                                .toList();

                String nextCursor = null;
                if (hasMore && !items.isEmpty()) {
                        // earliest item in this page becomes the "before" cursor for the next page
                        var earliest = items.get(0).createdAt();
                        nextCursor = earliest != null ? earliest.toString() : null;
                }

                return ResponseEntity.ok(new ChatHistoryResponse(items, nextCursor));
        }
}
