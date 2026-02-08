package com.learning.user_profile_service.model.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class UserProgressResponse {
    UUID id;
    UUID userId;
    Integer totalNotesViewed;
    Integer totalNotesCompleted;
    Integer totalMindmapsViewed;
    Integer totalMindmapsCompleted;
    Integer totalFlashcardsReviewed;
    Integer totalQuizzesAttempted;
    BigDecimal averageQuizScore;
    Long totalTimeSpentSeconds;
    BigDecimal knowledgeScore;
    Integer streakDays;
    Instant lastActivityAt;
    Instant createdAt;
    Instant updatedAt;
}
