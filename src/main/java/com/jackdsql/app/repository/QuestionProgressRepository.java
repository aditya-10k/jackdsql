package com.jackdsql.app.repository;

import com.jackdsql.app.model.QuestionProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface QuestionProgressRepository extends JpaRepository<QuestionProgress, Long> {
    long countByUserId(String userId);

    @Query("SELECT COUNT(qp) FROM QuestionProgress qp JOIN qp.question q " +
            "WHERE qp.userId = :userId AND q.difficulty = :difficulty")
    long countByUserIdAndDifficulty(@Param("userId") String userId, @Param("difficulty") String difficulty);

    boolean existsByUserIdAndQuestionId(String userId, String questionId);

    @Query("SELECT qp.question.id AS questionId, qp.completedAt AS completedAt " +
            "FROM QuestionProgress qp WHERE qp.userId = :userId")
    List<ActivityProjection> findActivityLogByUserId(@Param("userId") String userId);
}
