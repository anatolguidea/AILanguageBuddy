package com.example.ailanguagebuddy.controller;

import com.example.ailanguagebuddy.api.dto.LessonDto;
import com.example.ailanguagebuddy.api.dto.LessonSummaryDto;
import com.example.ailanguagebuddy.security.AuthUserResolver;
import com.example.ailanguagebuddy.service.LessonService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/lessons")
public class LessonController {

    private final LessonService lessonService;
    private final AuthUserResolver authUserResolver;

    public LessonController(LessonService lessonService, AuthUserResolver authUserResolver) {
        this.lessonService = lessonService;
        this.authUserResolver = authUserResolver;
    }

    @GetMapping
    public ResponseEntity<List<LessonDto>> getLessons(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String language) {
        var user = authUserResolver.fromJwt(jwt);
        return ResponseEntity.ok(lessonService.getLessonsForUser(user.userId(), language));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<Void> completeLesson(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable java.util.UUID id) {
        var user = authUserResolver.fromJwt(jwt);
        lessonService.completeLesson(user.userId(), id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/summary")
    public ResponseEntity<List<LessonSummaryDto>> getLessonSummaries(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String language) {
        var user = authUserResolver.fromJwt(jwt);
        return ResponseEntity.ok(lessonService.getLessonSummariesForUser(user.userId(), language));
    }

    @GetMapping("/{id}")
    public ResponseEntity<LessonDto> getLessonDetails(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable java.util.UUID id,
            @RequestParam(required = false) String language) {
        var user = authUserResolver.fromJwt(jwt);
        return ResponseEntity.ok(lessonService.getLessonForUser(user.userId(), id, language));
    }
}
