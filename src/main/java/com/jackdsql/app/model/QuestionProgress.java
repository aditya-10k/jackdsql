package com.jackdsql.app.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "question_progress",
        uniqueConstraints = {@UniqueConstraint(columnNames = {"user_id", "question_id"})})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuestionProgress {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    @Column(nullable = false)
    private boolean isCompleted = true;

    @Column(nullable = false)
    private Instant completedAt = Instant.now();
}
