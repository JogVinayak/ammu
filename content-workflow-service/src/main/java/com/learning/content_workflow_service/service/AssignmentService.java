package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.dto.AssignmentListResponse;
import com.learning.content_workflow_service.dto.AssignmentProgressResponse;
import com.learning.content_workflow_service.dto.AssignmentResponse;
import com.learning.content_workflow_service.dto.CreateAssignmentRequest;
import com.learning.content_workflow_service.dto.UpdateAssignmentRequest;
import com.learning.content_workflow_service.enums.AssignmentStatus;
import java.util.UUID;

public interface AssignmentService {

    AssignmentResponse createAssignment(String tenantId, String userId, CreateAssignmentRequest request);

    AssignmentResponse getAssignment(String tenantId, UUID assignmentId);

    AssignmentListResponse listAssignments(
            String tenantId, UUID classId, String teacherId, AssignmentStatus status, int page, int size);

    AssignmentResponse updateAssignment(
            String tenantId, UUID assignmentId, String userId, UpdateAssignmentRequest request);

    void cancelAssignment(String tenantId, UUID assignmentId);

    AssignmentListResponse listStudentAssignments(String tenantId, String studentId, int page, int size);

    AssignmentProgressResponse getAssignmentProgress(String tenantId, UUID assignmentId);
}
