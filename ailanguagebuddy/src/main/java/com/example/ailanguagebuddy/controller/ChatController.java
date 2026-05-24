package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.api.dto.ChatAskRequest;
import com.example.ailanguagebuddy.api.dto.ChatAskResponse;
import com.example.ailanguagebuddy.api.dto.ChatMessageDto;
import com.example.ailanguagebuddy.api.dto.ChatHistoryResponse;
import com.example.ailanguagebuddy.api.dto.CorrectionDto;
import com.example.ailanguagebuddy.api.dto.VocabularyItemDto;
import com.example.ailanguagebuddy.security.AuthUserResolver;
import com.example.ailanguagebuddy.service.ChatService;
import com.example.ailanguagebuddy.service.VoiceServiceClient;
import com.example.ailanguagebuddy.domain.LearningContext;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

        private static final Logger log = LoggerFactory.getLogger(ChatController.class);

        private final ChatService chatService;
        private final AuthUserResolver authUserResolver;
        private final VoiceServiceClient voiceServiceClient;

        public ChatController(
                        ChatService chatService,
                        AuthUserResolver authUserResolver,
                        VoiceServiceClient voiceServiceClient) {
                this.chatService = chatService;
                this.authUserResolver = authUserResolver;
                this.voiceServiceClient = voiceServiceClient;
        }

        @PostMapping("/ask")
        public ResponseEntity<ChatAskResponse> ask(
                        @AuthenticationPrincipal Jwt jwt,
                        @Valid @RequestBody ChatAskRequest request) {
                var user = authUserResolver.fromJwt(jwt);
                log.debug("/ask called: userId={}", user.userId());

                var ctx = new LearningContext(
                                request.targetLanguage(),
                                request.nativeLanguage(),
                                request.level(),
                                request.mode(),
                                request.instructionLocale() != null && !request.instructionLocale().isBlank()
                                        ? request.instructionLocale() : "en");
                var result = chatService.askLanguageCoach(request.message(), user.userId(), ctx);
                var correctionsDto = result.corrections() != null ? result.corrections().stream()
                                .map(c -> new CorrectionDto(c.original(), c.corrected(), c.explanation()))
                                .toList() : List.<CorrectionDto>of();
                var vocabDto = result.vocabulary() != null ? result.vocabulary().stream()
                                .map(v -> new VocabularyItemDto(v.term(), v.translation(), v.note()))
                                .toList() : List.<VocabularyItemDto>of();
                return ResponseEntity.ok(new ChatAskResponse(
                                result.replyText(),
                                result.translation(),
                                result.correction(),
                                result.tips(),
                                correctionsDto,
                                vocabDto));
        }

        @GetMapping("/initial")
        public ResponseEntity<ChatAskResponse> initial(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestParam(defaultValue = "general") String mode,
                        @RequestParam(required = false) String targetLanguage,
                        @RequestParam(required = false) String nativeLanguage,
                        @RequestParam(required = false) String level,
                        @RequestParam(required = false) String instructionLocale) {
                var user = authUserResolver.fromJwt(jwt);
                var ctx = new LearningContext(
                                targetLanguage != null ? targetLanguage : "English",
                                nativeLanguage != null ? nativeLanguage : "Romanian",
                                level != null ? level : "B1",
                                mode,
                                instructionLocale != null && !instructionLocale.isBlank() ? instructionLocale : "en");
                var result = chatService.getInitialMessage(user.userId(), ctx);
                return ResponseEntity.ok(new ChatAskResponse(
                                result.replyText(),
                                result.translation(),
                                result.correction(),
                                result.tips(),
                                List.of(),
                                List.of()));
        }

        @PostMapping("/voice/prewarm")
        public ResponseEntity<Void> prewarmVoice(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody(required = false) VoicePrewarmRequest request) {
                var user = authUserResolver.fromJwt(jwt);
                String languageCode = request != null ? request.languageCode() : "en";
                String targetLanguage = request != null ? request.targetLanguage() : "English";
                chatService.prewarmVoiceModel(
                                new LearningContext(
                                                targetLanguage == null || targetLanguage.isBlank()
                                                                ? "English"
                                                                : targetLanguage,
                                                "English",
                                                "A1",
                                                "VOICE_LIVE",
                                                "en"));
                voiceServiceClient.prewarm(languageCode);
                return ResponseEntity.noContent().build();
        }

        public record VoicePrewarmRequest(String languageCode, String targetLanguage) {
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
                                                m.getUserId(),
                                                m.getCorrection(),
                                                m.getTips()))
                                .toList();
                return ResponseEntity.ok(items);
        }

        private static final int MAX_HISTORY_LIMIT = 500;

        @GetMapping("/history/v2")
        public ResponseEntity<ChatHistoryResponse> historyV2(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestParam(defaultValue = "50") int limit,
                        @RequestParam(name = "cursor", required = false) String cursor,
                        @RequestParam(defaultValue = "general") String mode) {
                var user = authUserResolver.fromJwt(jwt);
                int safeLimit = Math.max(1, Math.min(limit, MAX_HISTORY_LIMIT));
                log.debug("/history/v2: userId={} mode={} limit={}", user.userId(), mode, safeLimit);

                LocalDateTime before = null;
                if (cursor != null && !cursor.isBlank()) {
                        try {
                                before = LocalDateTime.parse(cursor);
                        } catch (DateTimeParseException e) {
                                throw new IllegalArgumentException(
                                                "Invalid cursor format, expected ISO-8601 timestamp");
                        }
                }

                var raw = chatService.loadHistoryPage(user.userId(), mode, safeLimit, before);
                log.debug("/history/v2: found {} messages userId={}", raw.size(), user.userId());

                boolean hasMore = raw.size() > safeLimit;
                var pageItems = hasMore ? raw.subList(0, safeLimit) : raw;

                var items = pageItems.stream()
                                .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                                .map(m -> new ChatMessageDto(
                                                m.getId(),
                                                m.getContent(),
                                                m.getRole(),
                                                m.getCreatedAt(),
                                                m.getUserId(),
                                                m.getCorrection(),
                                                m.getTips()))
                                .toList();

                String nextCursor = null;
                if (hasMore && !items.isEmpty()) {
                        var earliest = items.get(0).createdAt();
                        nextCursor = earliest != null ? earliest.toString() : null;
                }

                return ResponseEntity.ok(new ChatHistoryResponse(items, nextCursor));
        }

        @DeleteMapping("/history")
        public ResponseEntity<Void> deleteHistory(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestParam(defaultValue = "general") String mode) {
                var user = authUserResolver.fromJwt(jwt);
                chatService.deleteHistory(user.userId(), mode);
                return ResponseEntity.noContent().build();
        }
}
