package com.learning.recall_service.service;

import com.learning.recall_service.dto.RecallAttemptRequest;
import com.learning.recall_service.dto.RecallAttemptResponse;
import com.learning.recall_service.dto.RecallScheduleResponse;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface RecallService {
    RecallAttemptResponse recordAttempt(UUID tenantId, UUID userId, RecallAttemptRequest request);

    RecallScheduleResponse getSchedule(UUID tenantId, UUID userId, UUID topicId);

    List<RecallScheduleResponse> getDue(UUID tenantId, UUID userId, Instant asOf, int limit);

    RecallScheduleResponse resetSchedule(UUID tenantId, UUID userId, UUID topicId);
}
