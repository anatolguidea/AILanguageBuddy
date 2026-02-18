package com.example.ailanguagebuddy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "lexemes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Lexeme {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "language_code", nullable = false, length = 10)
    private String languageCode;

    @Column(name = "theme_key", nullable = false, length = 50)
    private String themeKey;

    @Column(name = "english_word", nullable = false)
    private String englishWord;

    @Column(name = "english_phrase", length = 500)
    private String englishPhrase;

    @Column(name = "target_word", nullable = false)
    private String targetWord;

    @Column(name = "target_phrase", length = 500)
    private String targetPhrase;

    @Column(name = "correct_order", columnDefinition = "jsonb", nullable = false)
    @JdbcTypeCode(SqlTypes.JSON)
    private List<String> correctOrder;

    @Column(length = 20)
    private String emoji;

    @Column(name = "sort_order")
    private Integer sortOrder;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
