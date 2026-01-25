package com.learning.content_workflow_service.dto;

import com.learning.content_workflow_service.enums.WorkflowState;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class WorkflowResponse {
    private UUID workflowId;
    private String tenantId;
    private String contentId;
    private String contentVersionId;
    private String titleSnapshot;
    private WorkflowState state;
    private Integer requiredApprovals;
    private String createdBy;
    private Instant createdAt;
    private String lastUpdatedBy;
    private Instant lastUpdatedAt;
    private String currentStep;
    private PublishTargets publishTargets;
    private Long version;
}
