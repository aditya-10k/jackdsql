package com.jackdsql.app.service;

import com.jackdsql.app.dto.AiHintMessage;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.Question;

public interface AiProviderStrategy {

    AiProvider getProvider();

    String executeInference(AiHintMessage message , Question question);
}
