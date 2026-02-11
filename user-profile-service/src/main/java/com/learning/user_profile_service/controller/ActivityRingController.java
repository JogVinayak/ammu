package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.ActivityStreakResponse;
import com.learning.user_profile_service.model.dto.DailyActivityResponse;
import com.learning.user_profile_service.model.dto.WeeklySummaryResponse;
import com.learning.user_profile_service.service.ActivityRingService;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/users/{userId}/progress/activity-rings")
public class ActivityRingController {

    private final ActivityRingService activityRingService;

    @GetMapping("/today")
    public DailyActivityResponse getToday(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return activityRingService.getDailyActivity(tenantId, userId, LocalDate.now());
    }

    @GetMapping("/history")
    public List<DailyActivityResponse> getHistory(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return activityRingService.getActivityHistory(tenantId, userId, from, to);
    }

    @GetMapping("/streak")
    public ActivityStreakResponse getStreak(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return activityRingService.getStreakInfo(tenantId, userId);
    }

    @GetMapping("/weekly-summary")
    public WeeklySummaryResponse getWeeklySummary(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return activityRingService.getWeeklySummary(tenantId, userId);
    }
}
