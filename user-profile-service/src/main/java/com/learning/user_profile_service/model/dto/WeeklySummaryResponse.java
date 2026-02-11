package com.learning.user_profile_service.model.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class WeeklySummaryResponse {
    UUID userId;
    LocalDate from;
    LocalDate to;
    List<DailyActivityResponse> days;
    Integer daysWithActivity;
    Integer daysWithAllRingsClosed;
    Integer totalReadingCount;
    Integer totalFlashcardCount;
    Integer totalExamCount;
}
