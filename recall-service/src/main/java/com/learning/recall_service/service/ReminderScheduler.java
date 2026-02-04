package com.learning.recall_service.service;

import com.learning.recall_service.entity.RecallSchedule;
import com.learning.recall_service.repository.RecallScheduleRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "recall.reminders", name = "enabled", havingValue = "true", matchIfMissing = true)
public class ReminderScheduler {
    private final RecallScheduleRepository scheduleRepository;
    private final ReminderPublisher reminderPublisher;

    @Value("${recall.reminders.cooldown-seconds:3600}")
    private long cooldownSeconds;

    @Value("${recall.reminders.batch-size:200}")
    private int batchSize;

    @Scheduled(fixedDelayString = "${recall.reminders.interval-ms:60000}")
    @Transactional
    public void dispatchDueReminders() {
        Instant now = Instant.now();
        Instant minNotifiedAt = now.minusSeconds(Math.max(0, cooldownSeconds));
        List<RecallSchedule> due = scheduleRepository.findDueForReminder(
                now,
                minNotifiedAt,
                PageRequest.of(0, Math.max(1, batchSize))
        );

        if (due.isEmpty()) {
            return;
        }

        for (RecallSchedule schedule : due) {
            reminderPublisher.publishReminder(schedule);
            schedule.setLastNotifiedAt(now);
            schedule.setReminderCount(schedule.getReminderCount() + 1);
        }

        scheduleRepository.saveAll(due);
        log.info("Recall reminders dispatched: {}", due.size());
    }
}
