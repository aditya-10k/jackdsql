package com.jackdsql.app.service;

import com.jackdsql.app.repository.FoundationProgressRepository;
import com.jackdsql.app.repository.QuestionProgressRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class ActivityService {

    @Autowired
    private FoundationProgressRepository foundationProgressRepository ;

    @Autowired
    private QuestionProgressRepository questionProgressRepository;

    @Autowired
    private  StatsService statsService ;

//    public Map<LocalDate , Long> getActivityMap(String userId){
//
//        List<LocalDateTime> foundationDate = .findAllByUserId(userId);
//    }
}
