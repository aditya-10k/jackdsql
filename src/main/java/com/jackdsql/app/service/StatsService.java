package com.jackdsql.app.service;

import com.jackdsql.app.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class StatsService {

    private final FoundationRepository foundationRepo;
    private final QuestionRepository questionRepo;
    private final FoundationProgressRepository fProgressRepo;
    private final QuestionProgressRepository qProgressRepo;

    public Map<String, Object> getUserOverview(String userId) {
        long fTotal = foundationRepo.count();
        long fDone = fProgressRepo.countByUserId(userId);

        long qTotal = questionRepo.count();
        long qDone = qProgressRepo.countByUserId(userId);

        return Map.of(
                "foundations", Map.of("completed", fDone, "total", fTotal),
                "questions", Map.of("completed", qDone, "total", qTotal)
        );
    }

    public Map<LocalDate, List<String>> getCompletionHistory(String userId) {
        List<ActivityProjection> fActivities = fProgressRepo.findActivityLogByUserId(userId);
        List<ActivityProjection> qActivities = qProgressRepo.findActivityLogByUserId(userId);

        return Stream.concat(fActivities.stream(), qActivities.stream())
                .collect(Collectors.groupingBy(
                        a -> a.getCompletedAt().toLocalDate(),
                        Collectors.mapping(ActivityProjection::getQuestionId, Collectors.toList())
                ));
    }
}



