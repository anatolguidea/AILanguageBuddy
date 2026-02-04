package com.example.ailanguagebuddy.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "chat_messages")
@Getter
@Setter
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "TEXT")
    private String content;

    private String role; // 'user' or 'assistant'

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    /** Supabase auth.users.id (UUID); scopes messages per user. */
    @Column(columnDefinition = "uuid", name = "user_id")
    private UUID userId;

    public ChatMessage() {}

    public ChatMessage(String content, String role) {
        this.content = content;
        this.role = role;
    }

    public ChatMessage(String content, String role, UUID userId) {
        this.content = content;
        this.role = role;
        this.userId = userId;
    }
}