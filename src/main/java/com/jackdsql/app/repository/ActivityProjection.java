package com.jackdsql.app.repository;

import java.time.Instant;

public interface ActivityProjection {

    String getQuestionId();
    Instant getCompletedAt();
}
