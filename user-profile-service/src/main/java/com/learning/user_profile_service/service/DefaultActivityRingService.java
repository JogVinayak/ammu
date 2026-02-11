package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ActivityStreakResponse;
import com.learning.user_profile_service.model.dto.DailyActivityResponse;
import com.learning.user_profile_service.model.dto.WeeklySummaryResponse;
import com.learning.user_profile_service.model.entity.DailyActivity;
import com.learning.user_profile_service.model.enums.ActivityRingType;
import com.learning.user_profile_service.repository.DailyActivityRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultActivityRingService implements ActivityRingService {

    private final DailyActivityRepository dailyActivityRepository;

    @Override
    @Transactional
    public void recordActivity(UUID tenantId, UUID userId, ActivityRingType ringType) {
        LocalDate today = LocalDate.now();
        DailyActivity activity = findOrCreateToday(tenantId, userId, today);

        switch (ringType) {
            case READING:
                activity.setReadingCount(activity.getReadingCount() + 1);
                activity.setReadingRingClosed(true);
                break;
            case FLASHCARD:
                activity.setFlashcardCount(activity.getFlashcardCount() + 1);
                activity.setFlashcardRingClosed(true);
                break;
            case EXAM:
                activity.setExamCount(activity.getExamCount() + 1);
                activity.setExamRingClosed(true);
                break;
        }

        activity.setAllRingsClosed(
                activity.getReadingRingClosed()
                && activity.getFlashcardRingClosed()
                && activity.getExamRingClosed());

        activity.setUpdatedAt(Instant.now());
        dailyActivityRepository.save(activity);
    }

    @Override
    @Transactional(readOnly = true)
    public DailyActivityResponse getDailyActivity(UUID tenantId, UUID userId, LocalDate date) {
        return dailyActivityRepository
                .findByTenantIdAndUserIdAndActivityDate(tenantId, userId, date)
                .map(this::toResponse)
                .orElse(emptyResponse(userId, date));
    }

    @Override
    @Transactional(readOnly = true)
    public List<DailyActivityResponse> getActivityHistory(UUID tenantId, UUID userId,
                                                            LocalDate from, LocalDate to) {
        return dailyActivityRepository
                .findByTenantIdAndUserIdAndActivityDateBetweenOrderByActivityDateAsc(
                        tenantId, userId, from, to)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ActivityStreakResponse getStreakInfo(UUID tenantId, UUID userId) {
        LocalDate today = LocalDate.now();

        List<DailyActivity> recentDays = dailyActivityRepository
                .findByTenantIdAndUserIdAndActivityDateBetweenOrderByActivityDateDesc(
                        tenantId, userId, today.minusDays(365), today);

        int activityStreak = calculateStreak(recentDays, today, false);
        int allRingsStreak = calculateStreak(recentDays, today, true);

        return ActivityStreakResponse.builder()
                .userId(userId)
                .currentActivityStreak(activityStreak)
                .currentAllRingsStreak(allRingsStreak)
                .asOfDate(today)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public WeeklySummaryResponse getWeeklySummary(UUID tenantId, UUID userId) {
        LocalDate today = LocalDate.now();
        LocalDate weekAgo = today.minusDays(6);

        List<DailyActivityResponse> days = getActivityHistory(tenantId, userId, weekAgo, today);

        long daysWithActivity = days.stream()
                .filter(d -> d.getReadingCount() > 0
                        || d.getFlashcardCount() > 0
                        || d.getExamCount() > 0)
                .count();
        long daysWithAllRings = days.stream()
                .filter(DailyActivityResponse::getAllRingsClosed)
                .count();
        int totalReadings = days.stream()
                .mapToInt(DailyActivityResponse::getReadingCount).sum();
        int totalFlashcards = days.stream()
                .mapToInt(DailyActivityResponse::getFlashcardCount).sum();
        int totalExams = days.stream()
                .mapToInt(DailyActivityResponse::getExamCount).sum();

        return WeeklySummaryResponse.builder()
                .userId(userId)
                .from(weekAgo)
                .to(today)
                .days(days)
                .daysWithActivity((int) daysWithActivity)
                .daysWithAllRingsClosed((int) daysWithAllRings)
                .totalReadingCount(totalReadings)
                .totalFlashcardCount(totalFlashcards)
                .totalExamCount(totalExams)
                .build();
    }

    private DailyActivity findOrCreateToday(UUID tenantId, UUID userId, LocalDate today) {
        return dailyActivityRepository
                .findByTenantIdAndUserIdAndActivityDate(tenantId, userId, today)
                .orElseGet(() -> {
                    Instant now = Instant.now();
                    DailyActivity da = new DailyActivity();
                    da.setId(UUID.randomUUID());
                    da.setTenantId(tenantId);
                    da.setUserId(userId);
                    da.setActivityDate(today);
                    da.setReadingCount(0);
                    da.setFlashcardCount(0);
                    da.setExamCount(0);
                    da.setReadingRingClosed(false);
                    da.setFlashcardRingClosed(false);
                    da.setExamRingClosed(false);
                    da.setAllRingsClosed(false);
                    da.setCreatedAt(now);
                    da.setUpdatedAt(now);
                    return da;
                });
    }

    /**
     * Walk backwards from today through sorted (desc) daily activity records.
     * If requireAllRings is true, streak requires allRingsClosed = true.
     * Otherwise, any activity counts.
     */
    private int calculateStreak(List<DailyActivity> daysDesc, LocalDate today,
                                 boolean requireAllRings) {
        int streak = 0;
        LocalDate expectedDate = today;

        for (DailyActivity da : daysDesc) {
            if (!da.getActivityDate().equals(expectedDate)) {
                if (da.getActivityDate().isBefore(expectedDate)) {
                    break;
                }
                continue;
            }

            boolean qualifies = requireAllRings
                    ? Boolean.TRUE.equals(da.getAllRingsClosed())
                    : (da.getReadingCount() > 0
                        || da.getFlashcardCount() > 0
                        || da.getExamCount() > 0);

            if (qualifies) {
                streak++;
                expectedDate = expectedDate.minusDays(1);
            } else {
                break;
            }
        }

        return streak;
    }

    private DailyActivityResponse toResponse(DailyActivity da) {
        return DailyActivityResponse.builder()
                .id(da.getId())
                .userId(da.getUserId())
                .activityDate(da.getActivityDate())
                .readingCount(da.getReadingCount())
                .flashcardCount(da.getFlashcardCount())
                .examCount(da.getExamCount())
                .readingRingClosed(da.getReadingRingClosed())
                .flashcardRingClosed(da.getFlashcardRingClosed())
                .examRingClosed(da.getExamRingClosed())
                .allRingsClosed(da.getAllRingsClosed())
                .createdAt(da.getCreatedAt())
                .updatedAt(da.getUpdatedAt())
                .build();
    }

    private DailyActivityResponse emptyResponse(UUID userId, LocalDate date) {
        return DailyActivityResponse.builder()
                .userId(userId)
                .activityDate(date)
                .readingCount(0)
                .flashcardCount(0)
                .examCount(0)
                .readingRingClosed(false)
                .flashcardRingClosed(false)
                .examRingClosed(false)
                .allRingsClosed(false)
                .build();
    }
}
