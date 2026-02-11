package com.learning.content_workflow_service.controller;

import com.learning.content_workflow_service.dto.CreateWorkflowRequest;
import com.learning.content_workflow_service.dto.PublishWorkflowRequest;
import com.learning.content_workflow_service.dto.ReleaseContentRequest;
import com.learning.content_workflow_service.dto.ReleaseHistoryResponse;
import com.learning.content_workflow_service.dto.ReleasedContentResponse;
import com.learning.content_workflow_service.dto.ReviewActionRequest;
import com.learning.content_workflow_service.dto.SubmitForReviewRequest;
import com.learning.content_workflow_service.dto.WorkflowListResponse;
import com.learning.content_workflow_service.dto.WorkflowResponse;
import com.learning.content_workflow_service.enums.WorkflowState;
import com.learning.content_workflow_service.service.WorkflowService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
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

@RequiredArgsConstructor
@RestController
@RequestMapping("/workflow")
public class WorkflowController {
    private final WorkflowService workflowService;

    @PostMapping
    public ResponseEntity<WorkflowResponse> createWorkflow(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @Valid @RequestBody CreateWorkflowRequest request) {
        WorkflowResponse response = workflowService.createWorkflow(tenantId, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{workflowId}")
    public WorkflowResponse getWorkflow(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID workflowId) {
        return workflowService.getWorkflow(tenantId, workflowId);
    }

    @GetMapping
    public WorkflowListResponse listWorkflows(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestParam(required = false) String contentId,
            @RequestParam(required = false) WorkflowState state,
            @RequestParam(required = false) String createdBy,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return workflowService.listWorkflows(tenantId, contentId, state, createdBy, page, size);
    }

    @PostMapping("/{workflowId}/submit")
    public WorkflowResponse submitForReview(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID workflowId,
            @Valid @RequestBody SubmitForReviewRequest request) {
        return workflowService.submitForReview(tenantId, workflowId, userId, request);
    }

    @PostMapping("/{workflowId}/reviews/{taskId}/approve")
    public WorkflowResponse approveReview(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID workflowId,
            @PathVariable UUID taskId,
            @Valid @RequestBody ReviewActionRequest request) {
        return workflowService.approveReview(tenantId, workflowId, taskId, userId, request);
    }

    @PostMapping("/{workflowId}/reviews/{taskId}/reject")
    public WorkflowResponse rejectReview(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID workflowId,
            @PathVariable UUID taskId,
            @Valid @RequestBody ReviewActionRequest request) {
        return workflowService.rejectReview(tenantId, workflowId, taskId, userId, request);
    }

    @PostMapping("/{workflowId}/publish")
    public WorkflowResponse publish(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID workflowId,
            @RequestBody(required = false) PublishWorkflowRequest request) {
        return workflowService.publish(tenantId, workflowId, userId, request);
    }

    @PostMapping("/{workflowId}/archive")
    public WorkflowResponse archive(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID workflowId) {
        return workflowService.archive(tenantId, workflowId, userId);
    }

    @PostMapping("/release")
    public ResponseEntity<Void> releaseContent(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @Valid @RequestBody ReleaseContentRequest request) {
        workflowService.releaseContent(tenantId, userId, request);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/released")
    public List<ReleasedContentResponse> getReleasedContent(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestParam UUID classId,
            @RequestParam(required = false) String contentType) {
        return workflowService.getReleasedContent(tenantId, classId, contentType);
    }

    @GetMapping("/history")
    public ReleaseHistoryResponse getReleaseHistory(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return workflowService.getReleaseHistory(tenantId, userId, page, size);
    }
}
