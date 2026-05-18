package com.jackdsql.app.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_bookmarks",
        uniqueConstraints = {@UniqueConstraint(columnNames = {"user_id", "question_id"})})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserBookmark {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    @Column(nullable = false)
    private LocalDateTime bookmarkedAt = LocalDateTime.now();
}
