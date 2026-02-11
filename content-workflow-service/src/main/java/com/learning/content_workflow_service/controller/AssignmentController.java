package com.learning.content_workflow_service.controller;

import com.learning.content_workflow_service.dto.AssignmentListResponse;
import com.learning.content_workflow_service.dto.AssignmentProgressResponse;
import com.learning.content_workflow_service.dto.AssignmentResponse;
import com.learning.content_workflow_service.dto.CreateAssignmentRequest;
import com.learning.content_workflow_service.dto.UpdateAssignmentRequest;
import com.learning.content_workflow_service.enums.AssignmentStatus;
import com.learning.content_workflow_service.service.AssignmentService;
import jakarta.validation.Valid;
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
@RequestMapping("/assignments")
public class AssignmentController {

    private final AssignmentService assignmentService;

    @PostMapping
    public ResponseEntity<AssignmentResponse> createAssignment(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @Valid @RequestBody CreateAssignmentRequest request) {
        AssignmentResponse response = assignmentService.createAssignment(tenantId, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public AssignmentListResponse listAssignments(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestParam(required = false) UUID classId,
            @RequestParam(required = false) String teacherId,
            @RequestParam(required = false) AssignmentStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return assignmentService.listAssignments(tenantId, classId, teacherId, status, page, size);
    }

    @GetMapping("/{assignmentId}")
    public AssignmentResponse getAssignment(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID assignmentId) {
        return assignmentService.getAssignment(tenantId, assignmentId);
    }

    @PatchMapping("/{assignmentId}")
    public AssignmentResponse updateAssignment(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID assignmentId,
            @Valid @RequestBody UpdateAssignmentRequest request) {
        return assignmentService.updateAssignment(tenantId, assignmentId, userId, request);
    }

    @DeleteMapping("/{assignmentId}")
    public ResponseEntity<Void> cancelAssignment(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID assignmentId) {
        assignmentService.cancelAssignment(tenantId, assignmentId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/users/{userId}")
    public AssignmentListResponse listStudentAssignments(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return assignmentService.listStudentAssignments(tenantId, userId, page, size);
    }

    @GetMapping("/{assignmentId}/progress")
    public AssignmentProgressResponse getAssignmentProgress(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID assignmentId) {
        return assignmentService.getAssignmentProgress(tenantId, assignmentId);
    }
}
