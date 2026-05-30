package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.PreviewResponse;
import com.jackdsql.app.service.EvaluationService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/playground")
@RequiredArgsConstructor
public class PlaygroundController {

    @Autowired
    private EvaluationService evaluationService;

    @PostMapping()
    public ResponseEntity<PreviewResponse> runPlayground(@RequestBody Map<String , String> body){

        String userSql = body.getOrDefault("userSql" , "").trim();

        if(userSql.isEmpty()){
            return ResponseEntity.badRequest().body(new PreviewResponse(null , null , "Query is empty"));
        }

        String maliciouscheck = userSql.toUpperCase();

        if(maliciouscheck.contains("DROP DATABASE") || maliciouscheck.contains("ALTER SYSTEM")){
            return ResponseEntity.badRequest().body(
                    new PreviewResponse(null , null , "Malicious query detected , code rejected")
            );
        }

        PreviewResponse response = evaluationService.getOpenPlaygroundPreview(userSql);

        return ResponseEntity.ok(response);
    }
}
