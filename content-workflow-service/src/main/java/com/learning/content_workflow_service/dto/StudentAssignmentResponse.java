package com.learning.content_workflow_service.dto;

import com.learning.content_workflow_service.enums.StudentAssignmentStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class StudentAssignmentResponse {
    UUID studentAssignmentId;
    UUID assignmentId;
    String studentId;
    String studentName;
    StudentAssignmentStatus status;
    Instant startedAt;
    Instant completedAt;
    UUID recallScheduleId;
    Instant createdAt;
    Instant updatedAt;
}
