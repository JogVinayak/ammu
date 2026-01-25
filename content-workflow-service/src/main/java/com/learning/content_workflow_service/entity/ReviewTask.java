package com.learning.content_workflow_service.entity;

import com.learning.content_workflow_service.enums.ReviewTaskStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "review_tasks",
        indexes = {
            @Index(name = "idx_review_task_workflow", columnList = "workflow_id"),
            @Index(name = "idx_review_task_assignee", columnList = "assignee_user_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class ReviewTask {
    @Id
    @Column(name = "task_id")
    private UUID id;

    @Column(name = "workflow_id", nullable = false)
    private UUID workflowId;

    @Column(name = "assignee_user_id", nullable = false)
    private String assigneeUserId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReviewTaskStatus status;

    @Column(length = 2000)
    private String comment;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
