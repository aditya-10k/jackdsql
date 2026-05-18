package com.jackdsql.app.repository;

public interface QuestionListingProjection {
    String getId();
    String getTitle();
    String getDifficulty();
    String getDomain();
    Boolean getCompleted();
    Boolean getBookmarked();
}
