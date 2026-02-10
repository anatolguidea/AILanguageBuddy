package com.example.ailanguagebuddy.repository;

import com.example.ailanguagebuddy.model.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.jpa.repository.Query;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

        List<ChatMessage> findAllByOrderByCreatedAtDesc(Pageable pageable);

        List<ChatMessage> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

        List<ChatMessage> findByUserIdAndModeOrderByCreatedAtDesc(UUID userId, String mode, Pageable pageable);

        List<ChatMessage> findByUserIdAndCreatedAtLessThanOrderByCreatedAtDesc(
                        UUID userId,
                        LocalDateTime createdAt,
                        Pageable pageable);

        List<ChatMessage> findByUserIdAndModeAndCreatedAtLessThanOrderByCreatedAtDesc(
                        UUID userId,
                        String mode,
                        LocalDateTime createdAt,
                        Pageable pageable);
}
