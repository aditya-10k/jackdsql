package com.jackdsql.app.service;

import com.jackdsql.app.model.AiProvider;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class AiStrategyFactory {

    private final Map<AiProvider , AiProviderStrategy> strategies ;

    public AiStrategyFactory(List<AiProviderStrategy> strategyList){

        this.strategies = strategyList.stream()
                .collect(Collectors.toMap(AiProviderStrategy::getProvider ,strategy -> strategy));
    }

    public AiProviderStrategy getStrategy(AiProvider provider){

        AiProviderStrategy strategy = strategies.get(provider);

        if(strategy == null){
            throw new IllegalArgumentException("No concrete strategy implementation");
        }
        return strategy ;
    }
}
