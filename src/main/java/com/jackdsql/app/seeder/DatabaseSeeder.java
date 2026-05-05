package com.jackdsql.app.seeder;

import com.jackdsql.app.model.Question;
import com.jackdsql.app.repository.QuestionRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Component
@RequiredArgsConstructor
public class DatabaseSeeder implements CommandLineRunner {

    private final QuestionRepository questionRepository;
    private final ObjectMapper mapper;

    @Override
    public void run(String... args) throws Exception {
        InputStream inputStream = getClass().getResourceAsStream("/questions.json");

        if (inputStream == null) {
            System.out.println("Error: questions.json not found");
            return;
        }

        try {
            List<Question> jsonQuestions = mapper.readValue(inputStream, new TypeReference<List<Question>>() {});
            List<Question> newQuestions = new ArrayList<>();

            for (Question question : jsonQuestions) {
                if (!questionRepository.existsByQuestionText(question.getQuestionText())) {
                    newQuestions.add(question);
                }
            }

            if (!newQuestions.isEmpty()) {
                questionRepository.saveAll(newQuestions);
                System.out.println("Added: " + newQuestions.size());
            } else {
                System.out.println("No new questions");
            }

        } catch (Exception e) {
            System.err.println(e.getMessage());
            e.printStackTrace();
        }
    }
}