package com.example.ailanguagebuddy.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

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

    private String role; // 'user' sau 'assistant'

    private LocalDateTime createdAt = LocalDateTime.now();

    // Constructor gol necesar pentru JPA
    public ChatMessage() {}

    public ChatMessage(String content, String role) {
        this.content = content;
        this.role = role;
    }
}