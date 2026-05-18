package com.jackdsql.app.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String HINT_EXCHANGE = "ai.hint.exchange";
    public static final String HINT_QUEUE = "ai.hint.request.queue";
    public static final String HINT_ROUTING_KEY = "ai.hint.request";

    public static final String HINT_DLX = "ai.hint.dlx";
    public static final String HINT_DLQ = "ai.hint.deadletter.queue";
    public static final String HINT_DLX_ROUTING_KEY = "ai.hint.deadletter";

    @Bean
    public DirectExchange hintExchange(){
        return new DirectExchange(HINT_EXCHANGE , true ,false);
    }

    @Bean
    public Queue hintQueue(){
        return QueueBuilder.durable(HINT_QUEUE)
                .withArgument("x-dead-letter-exchange" , HINT_DLX)
                .withArgument("x-dead-letter-routing-key", HINT_DLX_ROUTING_KEY)
                .build();
    }

    @Bean
    public Binding hintBinding(Queue hintQueue , DirectExchange hintExchange){
        return BindingBuilder.bind(hintQueue).to(hintExchange).with(HINT_ROUTING_KEY);
    }

    @Bean
    public DirectExchange deadLetterExchange() {
        return new DirectExchange(HINT_DLX, true, false);
    }

    @Bean
    public Queue deadLetterQueue() {
        return QueueBuilder.durable(HINT_DLQ).build();
    }

    @Bean
    public Binding dlqBinding(Queue deadLetterQueue, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(deadLetterQueue).to(deadLetterExchange).with(HINT_DLX_ROUTING_KEY);
    }

    @Bean
    public Jackson2JsonMessageConverter jsonMessageConverter(){
        return new Jackson2JsonMessageConverter();
    }
}
