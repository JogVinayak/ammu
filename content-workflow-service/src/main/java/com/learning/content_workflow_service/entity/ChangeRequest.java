package com.learning.content_workflow_service.entity;

import com.learning.content_workflow_service.enums.ChangeRequestStatus;
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
        name = "change_requests",
        indexes = {
            @Index(name = "idx_change_request_workflow", columnList = "workflow_id"),
            @Index(name = "idx_change_request_requester", columnList = "requested_by_user_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class ChangeRequest {
    @Id
    @Column(name = "change_request_id")
    private UUID id;

    @Column(name = "workflow_id", nullable = false)
    private UUID workflowId;

    @Column(name = "requested_by_user_id", nullable = false)
    private String requestedByUserId;

    @Column(length = 200)
    private String summary;

    @Column(length = 4000)
    private String details;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ChangeRequestStatus status;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
