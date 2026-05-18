package com.jackdsql.app.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "foundation_progress" , uniqueConstraints = {@UniqueConstraint(columnNames = {"user_id" , "topic_id"})})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FoundationProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id ;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id" , nullable = false)
    private Foundation topic ;

    @Column(nullable = false)
    private boolean isCompleted = true ;

    @Column(nullable = false)
    private LocalDateTime completedAt = LocalDateTime.now();
}
