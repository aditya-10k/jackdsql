package com.jackdsql.app.dto;

import java.util.List;
import java.util.Map;

public record SubmissionResponse(
        boolean isCorrect , 
        String message,
        List<Map<String ,Object>> userOutput
){}
