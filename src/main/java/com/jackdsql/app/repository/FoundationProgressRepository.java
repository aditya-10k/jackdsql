package com.jackdsql.app.repository;

import com.jackdsql.app.model.FoundationProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FoundationProgressRepository extends JpaRepository<FoundationProgress, String> {
    long countByUserId(String userId);

    boolean existsByUserIdAndTopicId(String userId, String  topicId);

   @Query("SELECT fp.topic.id AS questionId, fp.completedAt AS completedAt " +
       "FROM FoundationProgress fp WHERE fp.userId = :userId")
    List<ActivityProjection> findActivityLogByUserId(@Param("userId") String userId);

}