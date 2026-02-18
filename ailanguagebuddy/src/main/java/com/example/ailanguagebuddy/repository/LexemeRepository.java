package com.example.ailanguagebuddy.repository;

import com.example.ailanguagebuddy.model.Lexeme;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LexemeRepository extends JpaRepository<Lexeme, UUID> {

    List<Lexeme> findByLanguageCodeAndThemeKeyOrderBySortOrderAsc(
            String languageCode,
            String themeKey
    );

    long countByLanguageCode(String languageCode);
}
