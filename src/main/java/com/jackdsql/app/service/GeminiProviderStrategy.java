package com.jackdsql.app.service;

import com.jackdsql.app.dto.AiHintMessage;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.Question;
import jakarta.persistence.Column;
import org.springframework.http.HttpEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;

import java.util.List;
import java.util.Map;

@Component
public class GeminiProviderStrategy implements AiProviderStrategy{

    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public AiProvider getProvider() {
        return AiProvider.GEMINI;
    }

    @Override
    public String executeInference(AiHintMessage message, Question question) {

        String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + message.getDecryptedApiKey();

        HttpHeaders headers = new HttpHeaders();

        String prompt;
        if ("playground".equals(question.getId())) {
            prompt = "You are an expert SQL teacher for JackDSQL application.\n" +
                     "Analyze the user's SQL query in a general database playground/sandbox environment and provide helpful suggestions, design tips, potential syntax improvements, or debugging hints.\n\n" +
                     "User's SQL Query Input:\n" + message.getUserSqlCode();
        } else {
            prompt = "You are an expert SQL teacher for JackDSQL application.\n" +
                     "Analyze the user's incorrect query and give a helpful hint. Do not give the solution query away.\n\n" +
                     "Exercise Prompt: " + question.getQuestionText() + "\n" +
                     "Database Table Schema Context:\n" + question.getSchemaSql() + "\n\n" +
                     "User's Broken Query Input: " + message.getUserSqlCode() + "\n" +
                     "Solution Query: " + question.getSolutionQuery();
        }

        Map<String , Object> requestBody = Map.of(
                "contents" , List.of(Map.of("role" , "user" , "parts", List.of(Map.of("text" , prompt)))),
                "generationConfig" , Map.of("temperature" , 0.2)
        );

        HttpEntity<Map<String ,Object>> entity = new HttpEntity<>(requestBody , headers);

        ResponseEntity<Map> response = restTemplate.postForEntity(url , entity, Map.class);

        List candidates = (List) response.getBody().get("candidates");
        Map firstCandidate = (Map) candidates.get(0);
        Map contentNode = (Map) firstCandidate.get("content");
        List parts = (List) contentNode.get("parts");
        Map firstPart = (Map) parts.get(0);

        return (String) firstPart.get("text");
    }
}
