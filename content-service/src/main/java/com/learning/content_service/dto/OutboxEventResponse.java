package com.learning.content_service.dto;

import com.learning.content_service.enums.OutboxStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class OutboxEventResponse {
    private UUID id;
    private String tenantId;
    private String aggregateType;
    private UUID aggregateId;
    private String eventType;
    private String payloadJson;
    private Instant createdAt;
    private Instant publishedAt;
    private OutboxStatus status;
}
