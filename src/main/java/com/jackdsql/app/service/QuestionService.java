package com.jackdsql.app.service;

import com.jackdsql.app.dto.QuestionDetailDTO;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.repository.QuestionListingProjection;
import com.jackdsql.app.repository.QuestionProgressRepository;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.repository.UserBookmarkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class QuestionService {

    @Autowired
    private QuestionRepository questionRepository ;

    @Autowired
    private QuestionProgressRepository questionProgressRepository ;

    @Autowired
    private UserBookmarkRepository userBookmarkRepository;

    public Map<String , List<QuestionListingProjection>> getGroupedQuestions(String userId){

        List<QuestionListingProjection> all = questionRepository.findAllWithStatus(userId);

        return all
                .stream()
                .collect(Collectors.groupingBy(QuestionListingProjection::getDifficulty));
    }

    public QuestionDetailDTO getQuestionDetail(String questionId, String userId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new RuntimeException("Question not found"));

        boolean completed = questionProgressRepository.existsByUserIdAndQuestionId(userId, questionId);
        boolean bookmarked = userBookmarkRepository.findByUserIdAndQuestionId(userId, questionId).isPresent();

        return QuestionDetailDTO.builder()
                .question(question)
                .isCompleted(completed)
                .isBookmarked(bookmarked)
                .build();
    }
}
