package com.jackdsql.app.service;

import com.jackdsql.app.config.RabbitMQConfig;
import com.jackdsql.app.dto.AiHintMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiHintProducerService {

    private final RabbitTemplate rabbitTemplate ;

    public void sendHintRequest(AiHintMessage message){
        log.info("Sending asymetric hint message task payload over queue trackinf Id :{}", message.getRequestId());

        rabbitTemplate.convertAndSend(
                RabbitMQConfig.HINT_EXCHANGE,
                RabbitMQConfig.HINT_ROUTING_KEY,
                message
        );
    }
}
