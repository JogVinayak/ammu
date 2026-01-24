package com.learning.content_service.controller;

import com.learning.content_service.dto.OutboxEventResponse;
import com.learning.content_service.enums.OutboxStatus;
import com.learning.content_service.service.OutboxService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/outbox")
public class OutboxController {
    private final OutboxService outboxService;

    @GetMapping
    public List<OutboxEventResponse> list(
            @RequestParam(defaultValue = "PENDING") OutboxStatus status,
            @RequestParam(defaultValue = "100") int limit) {
        return outboxService.listEvents(status, limit);
    }

    @PostMapping("/{eventId}/mark-published")
    public ResponseEntity<Void> markPublished(@PathVariable UUID eventId) {
        outboxService.markPublished(eventId);
        return ResponseEntity.noContent().build();
    }
}
