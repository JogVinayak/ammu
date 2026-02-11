package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ConceptMasteryState;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ConceptProgressResponse {
    UUID id;
    UUID userId;
    UUID noteId;
    ConceptMasteryState masteryState;
    Double memoryStrength;
    Double retention;
    Integer lastExamScore;
    Instant lastExamPassedAt;
    Integer totalExamAttempts;
    Integer passedExamCount;
    Integer totalFlashcardsReviewed;
    Integer totalReadingSessions;
    Instant lastReviewedAt;
    Instant masteryAchievedAt;
    Instant createdAt;
    Instant updatedAt;
}
