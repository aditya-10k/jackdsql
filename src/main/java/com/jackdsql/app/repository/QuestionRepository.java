package com.jackdsql.app.repository;

import com.jackdsql.app.model.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface QuestionRepository extends JpaRepository<Question ,String> {

    boolean existsByQuestionText(String questionText);
}
