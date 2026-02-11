package com.learning.content_workflow_service.dto;

import java.util.List;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AssignmentProgressResponse {
    UUID assignmentId;
    int totalStudents;
    int pendingCount;
    int inProgressCount;
    int completedCount;
    int overdueCount;
    List<StudentAssignmentResponse> studentAssignments;
}
