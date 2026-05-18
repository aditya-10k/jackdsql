package com.jackdsql.app.repository;

import com.jackdsql.app.model.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuestionRepository extends JpaRepository<Question ,String> {

    boolean existsByQuestionText(String questionText);

    @Query("SELECT q.id AS id, " +
            "q.questionTitle AS title, " +
            "q.difficulty AS difficulty, " +
            "q.domain AS domain, " +
            "(CASE WHEN qp.id IS NOT NULL THEN true ELSE false END) AS completed, " +
            "(CASE WHEN ub.id IS NOT NULL THEN true ELSE false END) AS bookmarked " +
            "FROM Question q " +
            "LEFT JOIN QuestionProgress qp ON qp.question = q AND qp.userId = :userId " +
            "LEFT JOIN UserBookmark ub ON ub.question = q AND ub.userId = :userId")
    List<QuestionListingProjection> findAllWithStatus(@Param("userId") String userId);
}

