package com.jackdsql.app.controllers;

import com.jackdsql.app.model.Foundation;
import com.jackdsql.app.model.FoundationProgress;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.FoundationProgressRepository;
import com.jackdsql.app.repository.FoundationRepository;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.EvaluationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("api/foundations/")
@CrossOrigin(origins = "*")
public class FoundationSubmissionController {

    @Autowired
    private FoundationRepository foundationRepository;

    @Autowired
    private EvaluationService evaluationService;

    @Autowired
    private FoundationProgressRepository foundationProgressRepository;

    @Autowired
    private UserRepository userRepository ;

    @PostMapping("/preview")
    public ResponseEntity<?> getPreview (@RequestBody Map<String ,String> request){

        String topicId = request.get("topic_id");
        Foundation foundation = foundationRepository.findById(topicId).orElseThrow();

        return ResponseEntity.ok(evaluationService.getPreview(foundation.getPracticeTasks().get(0), request.get("user_sql")));
    }

    @PostMapping("/submit")
    @Transactional
    public ResponseEntity<?> submit(@AuthenticationPrincipal UserDetails userDetails , @RequestBody Map<String , String> request){
        
        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        String topicId = request.get("topic_id");
        String userSql = request.get("user_sql");

        Foundation foundation = foundationRepository.findById(topicId).orElseThrow();

        boolean correct = evaluationService.compareResults(foundation.getPracticeTasks().get(0), userSql);

        if(correct && !foundationProgressRepository.existsByUserIdAndTopicId(userId,topicId)){

            foundationProgressRepository.save(FoundationProgress.builder()
                            .userId(userId)
                            .topic(foundation)
                            .completedAt(Instant.now())
                            .build());
        }

        return  ResponseEntity.ok(Map.of("is_correct" , correct));
    }

}
