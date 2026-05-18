package com.jackdsql.app.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record BookmarkResponse(
        String id,
        String questionId,
        String questionTitle,
        LocalDateTime bookmarkedAt
) {}
