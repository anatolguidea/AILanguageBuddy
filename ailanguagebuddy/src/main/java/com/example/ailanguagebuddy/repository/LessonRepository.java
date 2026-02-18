package com.example.ailanguagebuddy.repository;

import com.example.ailanguagebuddy.model.Lesson;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, UUID> {
    List<Lesson> findByLanguageCode(String languageCode, Sort sort);

    long countByLanguageCode(String languageCode);

    @Query("select coalesce(max(l.orderIndex), 0) from Lesson l where l.languageCode = :languageCode")
    Integer findMaxOrderIndexByLanguageCode(@Param("languageCode") String languageCode);

    @Modifying
    @Query("delete from Lesson l where l.languageCode = :languageCode")
    void deleteByLanguageCode(@Param("languageCode") String languageCode);
}
