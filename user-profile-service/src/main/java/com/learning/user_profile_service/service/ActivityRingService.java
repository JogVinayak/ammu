package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ActivityStreakResponse;
import com.learning.user_profile_service.model.dto.DailyActivityResponse;
import com.learning.user_profile_service.model.dto.WeeklySummaryResponse;
import com.learning.user_profile_service.model.enums.ActivityRingType;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface ActivityRingService {

    void recordActivity(UUID tenantId, UUID userId, ActivityRingType ringType);

    DailyActivityResponse getDailyActivity(UUID tenantId, UUID userId, LocalDate date);

    List<DailyActivityResponse> getActivityHistory(UUID tenantId, UUID userId,
                                                     LocalDate from, LocalDate to);

    ActivityStreakResponse getStreakInfo(UUID tenantId, UUID userId);

    WeeklySummaryResponse getWeeklySummary(UUID tenantId, UUID userId);
}
