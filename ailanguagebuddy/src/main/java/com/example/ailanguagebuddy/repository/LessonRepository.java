package com.example.ailanguagebuddy.repository;

import com.example.ailanguagebuddy.model.Lesson;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, UUID> {
    List<Lesson> findByLanguageCode(String languageCode, Sort sort);
}
