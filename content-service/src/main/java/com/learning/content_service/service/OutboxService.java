package com.learning.content_service.service;

import com.learning.content_service.dto.OutboxEventResponse;
import com.learning.content_service.entity.Content;
import com.learning.content_service.enums.OutboxStatus;
import java.util.List;
import java.util.UUID;

public interface OutboxService {
    void recordContentEvent(Content content, String eventType);

    List<OutboxEventResponse> listEvents(OutboxStatus status, int limit);

    void markPublished(UUID eventId);
}
