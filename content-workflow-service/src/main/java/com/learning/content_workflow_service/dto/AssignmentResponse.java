package com.learning.content_workflow_service.dto;

import com.learning.content_workflow_service.enums.AssignmentStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AssignmentResponse {
    UUID assignmentId;
    String tenantId;
    UUID noteId;
    UUID classId;
    String teacherId;
    String title;
    String description;
    AssignmentStatus status;
    Instant dueDate;
    CycleConfig cycleConfig;
    Integer studentCount;
    Instant createdAt;
    Instant updatedAt;
    Long version;
}
