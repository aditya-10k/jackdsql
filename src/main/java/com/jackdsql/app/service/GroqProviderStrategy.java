package com.jackdsql.app.service;

import com.jackdsql.app.dto.AiHintMessage;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.Question;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.server.reactive.HttpHandler;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;

import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class GroqProviderStrategy implements AiProviderStrategy{

    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public AiProvider getProvider() {
        return AiProvider.GROQ ;
    }

    @Override
    public String executeInference(AiHintMessage message, Question question) {

        String url = "https://api.groq.com/openai/v1/chat/completions";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(message.getDecryptedApiKey());

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

        Map<String, Object> requestBody = Map.of(
                "model", "llama-3.3-70b-versatile", // Low-latency, fast processing standard production model
                "messages", List.of(
                        Map.of("role", "user", "content", prompt)
                ),
                "temperature", 0.2
        );

        HttpEntity<Map<String,Object>> entity =new HttpEntity<>(requestBody , headers);

        ResponseEntity<Map> response = restTemplate.postForEntity(url , entity , Map.class);

        List choices = (List) response.getBody().get("choices");
        Map firstChoice = (Map) choices.get(0);
        Map messageNode = (Map) firstChoice.get("message");

        return (String) messageNode.get("content");

    }
}
