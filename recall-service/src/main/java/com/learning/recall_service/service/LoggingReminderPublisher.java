package com.learning.recall_service.service;

import com.learning.recall_service.entity.RecallSchedule;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class LoggingReminderPublisher implements ReminderPublisher {
    @Override
    public void publishReminder(RecallSchedule schedule) {
        log.info(
                "Recall reminder due: tenantId={}, userId={}, topicId={}, nextReviewAt={}",
                schedule.getTenantId(),
                schedule.getUserId(),
                schedule.getTopicId(),
                schedule.getNextReviewAt()
        );
    }
}
