package com.jackdsql.app.dto;

import java.util.List;
import java.util.Map;

public record SubmissionRequest(
        String questionId ,
        String userSql
) {}

