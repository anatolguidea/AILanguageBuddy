package com.example.ailanguagebuddy.service;

import com.example.ailanguagebuddy.api.dto.LessonDto;
import com.example.ailanguagebuddy.model.Lesson;
import com.example.ailanguagebuddy.model.UserLessonProgress;
import com.example.ailanguagebuddy.repository.LessonRepository;
import com.example.ailanguagebuddy.repository.UserLessonProgressRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class LessonService {

    private final LessonRepository lessonRepository;
    private final UserLessonProgressRepository progressRepository;

    public LessonService(LessonRepository lessonRepository, UserLessonProgressRepository progressRepository) {
        this.lessonRepository = lessonRepository;
        this.progressRepository = progressRepository;
    }

    public List<LessonDto> getLessonsForUser(UUID userId, String languageCode) {
        // 1. Fetch all lessons for the language, sorted by order
        List<Lesson> lessons = lessonRepository.findByLanguageCode(languageCode, Sort.by("orderIndex"));

        // 2. Fetch user progress
        List<UserLessonProgress> progressList = progressRepository.findByUserId(userId);
        Map<UUID, String> statusMap = progressList.stream()
                .collect(Collectors.toMap(UserLessonProgress::getLessonId, UserLessonProgress::getStatus));

        List<LessonDto> results = new ArrayList<>();
        boolean previousCompleted = true; // First lesson is available by default

        for (Lesson lesson : lessons) {
            String status = statusMap.getOrDefault(lesson.getId(), "locked");

            // Logic: If status is explicitly 'completed' or 'started', keep it.
            // If it's 'locked' (default), check if previous was completed.
            if (status.equals("locked")) {
                if (previousCompleted) {
                    status = "available";
                }
            }

            // Update previousCompleted for next iteration
            previousCompleted = "completed".equalsIgnoreCase(status);

            results.add(new LessonDto(
                    lesson.getId(),
                    lesson.getTitle(),
                    lesson.getDescription(),
                    status,
                    lesson.getContentJson(),
                    lesson.getOrderIndex() != null ? lesson.getOrderIndex() : 0));
        }

        return results;
    }

    public void completeLesson(UUID userId, UUID lessonId) {
        UserLessonProgress progress = progressRepository
                .findById(new com.example.ailanguagebuddy.model.UserLessonProgressId(userId, lessonId))
                .orElse(com.example.ailanguagebuddy.model.UserLessonProgress.builder()
                        .userId(userId)
                        .lessonId(lessonId)
                        .status("started")
                        .build());

        progress.setStatus("completed");
        progress.setCompletedAt(java.time.LocalDateTime.now());
        progress.setUpdatedAt(java.time.LocalDateTime.now());

        progressRepository.save(progress);
    }
}
