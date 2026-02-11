package com.learning.user_profile_service.model.dto;

import java.time.LocalDate;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ActivityStreakResponse {
    UUID userId;
    Integer currentActivityStreak;
    Integer currentAllRingsStreak;
    LocalDate asOfDate;
}
