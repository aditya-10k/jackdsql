package com.jackdsql.app.service;

import com.jackdsql.app.model.Foundation;
import com.jackdsql.app.repository.FoundationListingProjection;
import com.jackdsql.app.repository.FoundationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FoundationService {

    @Autowired
    private FoundationRepository foundationRepository;

    public List<FoundationListingProjection> getFoundationCatalogue(String userId){
        return foundationRepository.findAllWithStatus(userId);
    }

    public Foundation getTopicDetail(String id){
        return foundationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Foundation topic not found "+id));
    }
}
