package com.jackdsql.app.repository;

import java.time.LocalDateTime;

public interface ActivityProjection {

    String getQuestionId();
    LocalDateTime getCompletedAt();
}
