package com.example.ailanguagebuddy.repository;

import com.example.ailanguagebuddy.model.UserLessonProgress;
import com.example.ailanguagebuddy.model.UserLessonProgressId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserLessonProgressRepository extends JpaRepository<UserLessonProgress, UserLessonProgressId> {
    List<UserLessonProgress> findByUserId(UUID userId);
}
