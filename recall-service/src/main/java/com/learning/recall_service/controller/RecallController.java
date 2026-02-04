package com.learning.recall_service.controller;

import com.learning.recall_service.dto.RecallAttemptRequest;
import com.learning.recall_service.dto.RecallAttemptResponse;
import com.learning.recall_service.dto.RecallScheduleResponse;
import com.learning.recall_service.service.RecallService;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/recall")
@RequiredArgsConstructor
public class RecallController {
    private final RecallService recallService;

    @PostMapping("/attempts")
    public ResponseEntity<RecallAttemptResponse> recordAttempt(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody RecallAttemptRequest request) {
        RecallAttemptResponse response = recallService.recordAttempt(tenantId, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/schedule/{topicId}")
    public RecallScheduleResponse getSchedule(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID topicId) {
        return recallService.getSchedule(tenantId, userId, topicId);
    }

    @GetMapping("/due")
    public List<RecallScheduleResponse> getDue(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant asOf,
            @RequestParam(defaultValue = "50") int limit) {
        return recallService.getDue(tenantId, userId, asOf, limit);
    }

    @PostMapping("/schedule/{topicId}/reset")
    public RecallScheduleResponse resetSchedule(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID topicId) {
        return recallService.resetSchedule(tenantId, userId, topicId);
    }
}
