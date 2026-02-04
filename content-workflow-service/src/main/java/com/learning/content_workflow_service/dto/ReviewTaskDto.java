package com.learning.content_workflow_service.dto;

import com.learning.content_workflow_service.enums.ReviewTaskStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReviewTaskDto {
    private UUID id;
    private UUID workflowId;
    private String assigneeUserId;
    private ReviewTaskStatus status;
    private String comment;
    private Instant createdAt;
    private Instant updatedAt;
}