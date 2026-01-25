package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.dto.CreateWorkflowRequest;
import com.learning.content_workflow_service.dto.PublishWorkflowRequest;
import com.learning.content_workflow_service.dto.ReviewActionRequest;
import com.learning.content_workflow_service.dto.SubmitForReviewRequest;
import com.learning.content_workflow_service.dto.WorkflowListResponse;
import com.learning.content_workflow_service.dto.WorkflowResponse;
import com.learning.content_workflow_service.enums.WorkflowState;
import java.util.UUID;

public interface WorkflowService {
    WorkflowResponse createWorkflow(String tenantId, String userId, CreateWorkflowRequest request);

    WorkflowResponse getWorkflow(String tenantId, UUID workflowId);

    WorkflowListResponse listWorkflows(
            String tenantId,
            String contentId,
            WorkflowState state,
            String createdBy,
            int page,
            int size);

    WorkflowResponse submitForReview(
            String tenantId,
            UUID workflowId,
            String userId,
            SubmitForReviewRequest request);

    WorkflowResponse approveReview(
            String tenantId,
            UUID workflowId,
            UUID taskId,
            String userId,
            ReviewActionRequest request);

    WorkflowResponse rejectReview(
            String tenantId,
            UUID workflowId,
            UUID taskId,
            String userId,
            ReviewActionRequest request);

    WorkflowResponse publish(
            String tenantId,
            UUID workflowId,
            String userId,
            PublishWorkflowRequest request);

    WorkflowResponse archive(String tenantId, UUID workflowId, String userId);
}
