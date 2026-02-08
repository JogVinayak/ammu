package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.ContentProgressResponse;
import com.learning.user_profile_service.model.dto.KnowledgeCoverageResponse;
import com.learning.user_profile_service.model.dto.MindmapCoverageResponse;
import com.learning.user_profile_service.model.dto.RecordNodeReviewRequest;
import com.learning.user_profile_service.model.dto.RecordProgressRequest;
import com.learning.user_profile_service.model.dto.UserProgressResponse;
import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.service.ProgressService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/users/{userId}/progress")
public class ProgressController {
    private final ProgressService progressService;

    // User aggregate progress
    @GetMapping
    public UserProgressResponse getUserProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return progressService.getUserProgress(tenantId, userId);
    }

    // Content progress
    @PostMapping("/content")
    public ContentProgressResponse recordProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @Valid @RequestBody RecordProgressRequest request) {
        return progressService.recordProgress(tenantId, userId, request);
    }

    @GetMapping("/content")
    public List<ContentProgressResponse> getUserContentProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestParam(required = false) ContentType type) {
        if (type != null) {
            return progressService.getUserContentProgressByType(tenantId, userId, type);
        }
        return progressService.getUserContentProgress(tenantId, userId);
    }

    @GetMapping("/content/{contentId}")
    public ContentProgressResponse getContentProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @PathVariable UUID contentId,
            @RequestParam ContentType type) {
        return progressService.getContentProgress(tenantId, userId, contentId, type);
    }

    // Knowledge coverage
    @PostMapping("/knowledge")
    public KnowledgeCoverageResponse recordNodeReview(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @Valid @RequestBody RecordNodeReviewRequest request) {
        return progressService.recordNodeReview(tenantId, userId, request);
    }

    @GetMapping("/knowledge/mindmap/{mindmapId}")
    public MindmapCoverageResponse getMindmapCoverage(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @PathVariable UUID mindmapId,
            @RequestParam(defaultValue = "0") int totalNodes) {
        return progressService.getMindmapCoverage(tenantId, userId, mindmapId, totalNodes);
    }

    @GetMapping("/knowledge/due-for-review")
    public List<KnowledgeCoverageResponse> getDueForReview(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "10") int limit) {
        return progressService.getDueForReview(userId, limit);
    }
}
