package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.PreviewResponse;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.model.QuestionProgress;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.QuestionProgressRepository;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.EvaluationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("api/questions")
@CrossOrigin(origins = "*")
public class QuestionsSubmissionController {

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private EvaluationService evaluationService;

    @Autowired
    private QuestionProgressRepository questionProgressRepository;

    @Autowired
    private UserRepository userRepository ;

    @PostMapping("/preview")
    public ResponseEntity<?> getPreview(@RequestBody Map<String, String> request) {
        String questionId = request.get("question_id");
        Question q = questionRepository.findById(questionId)
                .orElse(null);

        if (q == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Question not found with id: " + questionId));
        }

        return ResponseEntity.ok(evaluationService.getPreview(q, request.get("user_sql")));
    }

    @PostMapping("/submit")
    @Transactional
    public ResponseEntity<?> submit(@RequestBody Map<String, String> request , @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        String questionId = request.get("question_id");
        String userSql = request.get("user_sql");

        Question q = questionRepository.findById(questionId).orElse(null);
        if (q == null) return ResponseEntity.badRequest().body("Question not found");

        boolean correct = evaluationService.compareResults(q, userSql);

        // Update Progress if correct
        if (correct && !questionProgressRepository.existsByUserIdAndQuestionId(userId, questionId)) {
            questionProgressRepository.save(QuestionProgress.builder()
                    .userId(userId)
                    .question(q)
                    .completedAt(LocalDateTime.now())
                    .build());
        }

        return ResponseEntity.ok(Map.of("is_correct", correct));
    }
}
