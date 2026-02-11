package com.learning.user_profile_service.model.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class DailyActivityResponse {
    UUID id;
    UUID userId;
    LocalDate activityDate;
    Integer readingCount;
    Integer flashcardCount;
    Integer examCount;
    Boolean readingRingClosed;
    Boolean flashcardRingClosed;
    Boolean examRingClosed;
    Boolean allRingsClosed;
    Instant createdAt;
    Instant updatedAt;
}
