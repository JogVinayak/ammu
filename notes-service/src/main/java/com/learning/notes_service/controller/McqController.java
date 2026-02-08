package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.BatchMcqsRequest;
import com.learning.notes_service.model.dto.CreateMcqRequest;
import com.learning.notes_service.model.dto.McqListResponse;
import com.learning.notes_service.model.dto.McqResponse;
import com.learning.notes_service.model.dto.UpdateMcqRequest;
import com.learning.notes_service.service.McqService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/notes/{noteId}/mcqs")
public class McqController {
    private final McqService mcqService;

    @PostMapping
    public ResponseEntity<McqResponse> create(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody CreateMcqRequest request) {
        McqResponse response = mcqService.create(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public McqListResponse list(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam(required = false) String difficulty) {
        if (difficulty != null && !difficulty.isEmpty()) {
            return mcqService.listByNoteAndDifficulty(tenantId, noteId, difficulty);
        }
        return mcqService.listByNote(tenantId, noteId);
    }

    @GetMapping("/{mcqId}")
    public McqResponse getById(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID mcqId) {
        return mcqService.getById(tenantId, noteId, mcqId);
    }

    @PatchMapping("/{mcqId}")
    public McqResponse update(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID mcqId,
            @RequestBody UpdateMcqRequest request) {
        return mcqService.update(tenantId, noteId, mcqId, request);
    }

    @DeleteMapping("/{mcqId}")
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID mcqId) {
        mcqService.delete(tenantId, noteId, mcqId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/batch")
    public McqListResponse batchUpsert(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody BatchMcqsRequest request) {
        return mcqService.batchUpsert(tenantId, noteId, request);
    }
}
