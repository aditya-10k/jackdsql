package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.PreviewResponse;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.service.EvaluationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("api/submissions")
@CrossOrigin(origins = "*")
public class SubmissionController {

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private EvaluationService evaluationService;

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
    public ResponseEntity<?> submit(@RequestBody Map<String, String> request) {
        String questionId = request.get("question_id");
        Question q = questionRepository.findById(questionId)
                .orElse(null);

        if (q == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Question not found with id: " + questionId));
        }

        boolean correct = evaluationService.compareResults(q, request.get("user_sql"));
        return ResponseEntity.ok(Map.of("is_correct", correct));
    }
}
