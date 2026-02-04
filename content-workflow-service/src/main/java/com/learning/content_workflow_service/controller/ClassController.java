package com.learning.content_workflow_service.controller;

import com.learning.content_workflow_service.dto.ClassListResponse;
import com.learning.content_workflow_service.dto.ClassResponse;
import com.learning.content_workflow_service.dto.CreateClassRequest;
import com.learning.content_workflow_service.dto.UpdateClassRequest;
import com.learning.content_workflow_service.service.SchoolClassService;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/classes")
public class ClassController {
    private final SchoolClassService classService;

    @PostMapping
    public ResponseEntity<ClassResponse> createClass(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @Valid @RequestBody CreateClassRequest request) {
        ClassResponse response = classService.createClass(tenantId, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{classId}")
    public ClassResponse getClass(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID classId) {
        return classService.getClass(tenantId, classId);
    }

    @GetMapping
    public ClassListResponse listClasses(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestParam(required = false) String grade,
            @RequestParam(required = false) String subject,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return classService.listClasses(tenantId, userId, grade, subject, page, size);
    }

    @PutMapping("/{classId}")
    public ClassResponse updateClass(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @PathVariable UUID classId,
            @Valid @RequestBody UpdateClassRequest request) {
        return classService.updateClass(tenantId, classId, userId, request);
    }

    @DeleteMapping("/{classId}")
    public ResponseEntity<Void> deleteClass(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID classId) {
        classService.deleteClass(tenantId, classId);
        return ResponseEntity.noContent().build();
    }
}
