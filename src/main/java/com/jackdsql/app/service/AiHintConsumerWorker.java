package com.jackdsql.app.service;

import com.jackdsql.app.config.RabbitMQConfig;
import com.jackdsql.app.dto.AiHintMessage;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.model.UserApiKey;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.repository.SseEmittersRepository;
import com.jackdsql.app.repository.UserApiRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;

@Component
@Slf4j
@RequiredArgsConstructor
public class AiHintConsumerWorker {

    @Autowired
    private QuestionRepository questionRepository ;

    private final RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private AiStrategyFactory strategyFactory ;

    @Autowired
    private UserApiRepository userApiRepository ;

    @Autowired
    private TextEncryptor textEncryptor ;

    @Autowired
    private SseEmittersRepository sseEmittersRepository ;

    @RabbitListener(queues = RabbitMQConfig.HINT_QUEUE)
    public void processIncomingHintRequest(AiHintMessage message) {
        log.info("RabbitMQ Worker processing task tracking ID: {}", message.getRequestId());

        try {
            Question question;
            if ("playground".equals(message.getQuestionId())) {
                question = new Question();
                question.setId("playground");
                question.setSource("playground");
                question.setDomain("playground");
                question.setDifficulty("easy");
                question.setQuestionTitle("SQL Playground");
                question.setQuestionText("Analyze the user's SQL query and provide syntax, design, or logical improvement suggestions.");
                question.setSchemaSql("N/A (General sandbox environment)");
                question.setSolutionQuery("N/A");
            } else {
                question = questionRepository.findById(message.getQuestionId())
                        .orElseThrow(() -> new IllegalArgumentException("Question location index invalid: "));
            }

            String generatedHint = "";

            try {
                log.info("Primary execution attempt using AI Provider: [{}]", message.getProvider());
                AiProviderStrategy primaryStrategy = strategyFactory.getStrategy(message.getProvider());
                generatedHint = primaryStrategy.executeInference(message, question);

            } catch (Exception primaryException) {
                log.warn("Primary provider [{}] failed (Token exhaustion/API Error). Catching vector to initiate auto-fallback...",
                        message.getProvider(), primaryException);

                generatedHint = executeAutomaticFailover(message, question, primaryException);
            }

            log.info("Successfully resolved execution query pipeline for Request ID: {}", message.getRequestId());
            log.info("Resulting hint output text: \n{}", generatedHint);

            SseEmitter activeStream = sseEmittersRepository.get(message.getUserId());

            if(activeStream != null){
                try {
                    Map<String ,String > data = Map.of(
                            "requestId" , message.getRequestId(),
                            "questionId" , message.getQuestionId(),
                            "hint" , generatedHint);

                    activeStream.send(SseEmitter.event().name("AI Hint").data(data));
                    log.info("Hint push successfully via SSE");
                } catch (Exception e) {
                    log.warn("Failed to delever Hint via SSE");
                    sseEmittersRepository.delete(message.getUserId());
                }
            }

        } catch (Exception fatalException) {
            log.error("CRITICAL: All fallback strategy vectors completely exhausted for Request ID: {}", message.getRequestId(), fatalException);
            throw new org.springframework.amqp.AmqpRejectAndDontRequeueException(fatalException);
        }
    }

    private String executeAutomaticFailover(AiHintMessage message, Question question, Exception originalException) {
        log.info("Scanning database to locate alternative active backup keys for user ID: {}", message.getUserId());

        List<UserApiKey> savedKeys = userApiRepository.findByUserApiKeyId_UserId(message.getUserId());

        UserApiKey fallbackKeyEntity = savedKeys.stream()
                .filter(key -> key.getUserApiKeyId().getProvider() != message.getProvider())
                .findFirst()
                .orElseThrow(() -> new RuntimeException(
                        "No alternative secondary backup key configured by user. Cannot auto-switch profiles. Original error: "
                                + originalException.getMessage(), originalException));

        AiProvider backupProvider = fallbackKeyEntity.getUserApiKeyId().getProvider();
        log.info("Valid fallback vector verified! Auto-switching application layer over to provider: [{}]", backupProvider);

        String decryptedBackupKey = textEncryptor.decrypt(fallbackKeyEntity.getEncryptedApiKey());

        message.setProvider(backupProvider);
        message.setDecryptedApiKey(decryptedBackupKey);

        AiProviderStrategy fallbackStrategy = strategyFactory.getStrategy(backupProvider);

        return fallbackStrategy.executeInference(message, question);
    }


}
