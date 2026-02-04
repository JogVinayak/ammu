package com.learning.recall_service.service;

import com.learning.recall_service.entity.RecallSchedule;

public interface ReminderPublisher {
    void publishReminder(RecallSchedule schedule);
}
