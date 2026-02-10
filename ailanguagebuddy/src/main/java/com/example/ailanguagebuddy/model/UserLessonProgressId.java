package com.example.ailanguagebuddy.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserLessonProgressId implements Serializable {
    private UUID userId;
    private UUID lessonId;
}
