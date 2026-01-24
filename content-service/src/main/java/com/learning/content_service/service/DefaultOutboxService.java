package com.learning.content_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.content_service.dto.OutboxEventResponse;
import com.learning.content_service.entity.Content;
import com.learning.content_service.entity.OutboxEvent;
import com.learning.content_service.enums.OutboxStatus;
import com.learning.content_service.exception.NotFoundException;
import com.learning.content_service.repository.OutboxEventRepository;
import com.learning.content_service.util.AccessGuard;
import com.learning.content_service.util.TenantContext;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultOutboxService implements OutboxService {
    private static final String AGGREGATE_TYPE = "CONTENT";
    private static final int MAX_LIMIT = 500;

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;
    private final AccessGuard accessGuard;

    @Override
    @Transactional
    public void recordContentEvent(Content content, String eventType) {
        OutboxEvent event = new OutboxEvent();
        event.setId(UUID.randomUUID());
        event.setTenantId(content.getTenantId());
        event.setAggregateType(AGGREGATE_TYPE);
        event.setAggregateId(content.getId());
        event.setEventType(eventType);
        event.setPayloadJson(buildPayload(content));
        event.setCreatedAt(Instant.now());
        event.setStatus(OutboxStatus.PENDING);
        outboxEventRepository.save(event);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OutboxEventResponse> listEvents(OutboxStatus status, int limit) {
        TenantContext context = accessGuard.requireRead().getContext();
        int normalizedLimit = Math.min(Math.max(limit, 1), MAX_LIMIT);
        OutboxStatus effectiveStatus = status == null ? OutboxStatus.PENDING : status;
        PageRequest pageRequest = PageRequest.of(0, normalizedLimit, Sort.by("createdAt").ascending());
        return outboxEventRepository.findByTenantIdAndStatus(context.getTenantId(), effectiveStatus, pageRequest)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void markPublished(UUID eventId) {
        TenantContext context = accessGuard.requireWrite();
        OutboxEvent event = outboxEventRepository.findByIdAndTenantId(eventId, context.getTenantId())
                .orElseThrow(() -> new NotFoundException("Outbox event not found"));
        event.setStatus(OutboxStatus.PUBLISHED);
        event.setPublishedAt(Instant.now());
        outboxEventRepository.save(event);
    }

    private String buildPayload(Content content) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contentId", content.getId());
        payload.put("tenantId", content.getTenantId());
        payload.put("type", content.getType());
        payload.put("status", content.getStatus());
        payload.put("currentVersion", content.getCurrentVersion());
        payload.put("latestDraftVersion", content.getLatestDraftVersion());
        payload.put("title", content.getTitle());
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize outbox payload", ex);
        }
    }

    private OutboxEventResponse toResponse(OutboxEvent event) {
        OutboxEventResponse response = new OutboxEventResponse();
        response.setId(event.getId());
        response.setTenantId(event.getTenantId());
        response.setAggregateType(event.getAggregateType());
        response.setAggregateId(event.getAggregateId());
        response.setEventType(event.getEventType());
        response.setPayloadJson(event.getPayloadJson());
        response.setCreatedAt(event.getCreatedAt());
        response.setPublishedAt(event.getPublishedAt());
        response.setStatus(event.getStatus());
        return response;
    }
}
