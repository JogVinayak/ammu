package com.learning.recall_service.service;

import com.learning.recall_service.dto.RecallAttemptRequest;
import com.learning.recall_service.dto.RecallAttemptResponse;
import com.learning.recall_service.dto.RecallScheduleResponse;
import com.learning.recall_service.entity.RecallEvent;
import com.learning.recall_service.entity.RecallSchedule;
import com.learning.recall_service.model.RecallOption;
import com.learning.recall_service.repository.RecallEventRepository;
import com.learning.recall_service.repository.RecallScheduleRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
@Transactional
public class DefaultRecallService implements RecallService {
    private static final long MIN_INTERVAL_SECONDS = 600; // 10 minutes
    private static final long MAX_INTERVAL_SECONDS = 15_552_000; // 180 days

    private static final long INITIAL_AGAIN = 600; // 10 minutes
    private static final long INITIAL_HARD = 86_400; // 1 day
    private static final long INITIAL_GOOD = 259_200; // 3 days
    private static final long INITIAL_EASY = 604_800; // 7 days

    private final RecallScheduleRepository scheduleRepository;
    private final RecallEventRepository eventRepository;

    @Override
    public RecallAttemptResponse recordAttempt(UUID tenantId, UUID userId, RecallAttemptRequest request) {
        Instant occurredAt = request.getOccurredAt() != null ? request.getOccurredAt() : Instant.now();
        RecallOption option = request.getOption();

        RecallSchedule schedule = scheduleRepository
                .findByTenantIdAndUserIdAndTopicId(tenantId, userId, request.getTopicId())
                .orElse(null);

        boolean isFirstAttempt = schedule == null;
        if (schedule == null) {
            schedule = new RecallSchedule();
            schedule.setId(UUID.randomUUID());
            schedule.setTenantId(tenantId);
            schedule.setUserId(userId);
            schedule.setTopicId(request.getTopicId());
            schedule.setEaseFactor(2.5);
            schedule.setReminderCount(0);
            schedule.setStreak(0);
            schedule.setLapseCount(0);
        }

        long intervalSeconds = isFirstAttempt
                ? initialIntervalSeconds(option)
                : nextIntervalSeconds(schedule.getIntervalSeconds(), option);

        int streak = schedule.getStreak();
        int lapseCount = schedule.getLapseCount();
        double easeFactor = adjustEaseFactor(schedule.getEaseFactor(), option);

        if (option == RecallOption.AGAIN) {
            streak = 0;
            lapseCount += 1;
        } else {
            streak += 1;
        }

        schedule.setLastOption(option);
        schedule.setIntervalSeconds(intervalSeconds);
        schedule.setLastReviewedAt(occurredAt);
        schedule.setNextReviewAt(occurredAt.plusSeconds(intervalSeconds));
        schedule.setStreak(streak);
        schedule.setLapseCount(lapseCount);
        schedule.setEaseFactor(easeFactor);
        schedule.setLastNotifiedAt(null);
        schedule.setReminderCount(0);

        scheduleRepository.save(schedule);

        RecallEvent event = new RecallEvent();
        event.setId(UUID.randomUUID());
        event.setTenantId(tenantId);
        event.setUserId(userId);
        event.setTopicId(request.getTopicId());
        event.setOption(option);
        event.setTimeSpentSeconds(request.getTimeSpentSeconds());
        event.setOccurredAt(occurredAt);
        event.setCalculatedIntervalSeconds(intervalSeconds);
        event.setNextReviewAt(schedule.getNextReviewAt());
        eventRepository.save(event);

        return RecallAttemptResponse.builder()
                .topicId(request.getTopicId())
                .option(option)
                .intervalSeconds(intervalSeconds)
                .nextReviewAt(schedule.getNextReviewAt())
                .streak(streak)
                .easeFactor(easeFactor)
                .lastReviewedAt(schedule.getLastReviewedAt())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public RecallScheduleResponse getSchedule(UUID tenantId, UUID userId, UUID topicId) {
        RecallSchedule schedule = scheduleRepository
                .findByTenantIdAndUserIdAndTopicId(tenantId, userId, topicId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Schedule not found"));
        return toResponse(schedule);
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecallScheduleResponse> getDue(UUID tenantId, UUID userId, Instant asOf, int limit) {
        Instant effectiveAsOf = asOf != null ? asOf : Instant.now();
        List<RecallSchedule> due = scheduleRepository.findDueForUser(
                tenantId,
                userId,
                effectiveAsOf,
                PageRequest.of(0, Math.max(1, limit))
        );
        return due.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public RecallScheduleResponse resetSchedule(UUID tenantId, UUID userId, UUID topicId) {
        RecallSchedule schedule = scheduleRepository
                .findByTenantIdAndUserIdAndTopicId(tenantId, userId, topicId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Schedule not found"));

        Instant now = Instant.now();
        schedule.setLastOption(RecallOption.AGAIN);
        schedule.setIntervalSeconds(INITIAL_AGAIN);
        schedule.setLastReviewedAt(now);
        schedule.setNextReviewAt(now.plusSeconds(INITIAL_AGAIN));
        schedule.setStreak(0);
        schedule.setLapseCount(0);
        schedule.setEaseFactor(2.5);
        schedule.setLastNotifiedAt(null);
        schedule.setReminderCount(0);

        scheduleRepository.save(schedule);
        return toResponse(schedule);
    }

    private RecallScheduleResponse toResponse(RecallSchedule schedule) {
        return RecallScheduleResponse.builder()
                .topicId(schedule.getTopicId())
                .lastOption(schedule.getLastOption())
                .intervalSeconds(schedule.getIntervalSeconds())
                .nextReviewAt(schedule.getNextReviewAt())
                .lastReviewedAt(schedule.getLastReviewedAt())
                .streak(schedule.getStreak())
                .easeFactor(schedule.getEaseFactor())
                .lapseCount(schedule.getLapseCount())
                .build();
    }

    private long initialIntervalSeconds(RecallOption option) {
        return switch (option) {
            case AGAIN -> INITIAL_AGAIN;
            case HARD -> INITIAL_HARD;
            case GOOD -> INITIAL_GOOD;
            case EASY -> INITIAL_EASY;
        };
    }

    private long nextIntervalSeconds(long previousInterval, RecallOption option) {
        double multiplier = switch (option) {
            case AGAIN -> 0.5;
            case HARD -> 1.2;
            case GOOD -> 2.0;
            case EASY -> 3.0;
        };
        long computed = Math.round(previousInterval * multiplier);
        if (computed < MIN_INTERVAL_SECONDS) {
            return MIN_INTERVAL_SECONDS;
        }
        if (computed > MAX_INTERVAL_SECONDS) {
            return MAX_INTERVAL_SECONDS;
        }
        return computed;
    }

    private double adjustEaseFactor(double current, RecallOption option) {
        double updated = switch (option) {
            case AGAIN -> current - 0.2;
            case HARD -> current - 0.05;
            case GOOD -> current;
            case EASY -> current + 0.15;
        };
        if (updated < 1.3) {
            return 1.3;
        }
        if (updated > 3.0) {
            return 3.0;
        }
        return updated;
    }
}
