package com.learning.content_workflow_service.entity;

import com.learning.content_workflow_service.enums.WorkflowState;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "workflows",
        indexes = {
            @Index(name = "idx_workflow_tenant_content", columnList = "tenant_id,content_id"),
            @Index(name = "idx_workflow_tenant_content_version", columnList = "tenant_id,content_version_id"),
            @Index(name = "idx_workflow_tenant_state", columnList = "tenant_id,state"),
            @Index(name = "idx_workflow_tenant_created_by", columnList = "tenant_id,created_by")
        })
@Getter
@Setter
@NoArgsConstructor
public class Workflow {
    @Id
    @Column(name = "workflow_id")
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "content_id", nullable = false)
    private String contentId;

    @Column(name = "content_version_id", nullable = false)
    private String contentVersionId;

    @Column(name = "title_snapshot", length = 200)
    private String titleSnapshot;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private WorkflowState state;

    @Column(name = "required_approvals")
    private Integer requiredApprovals;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "last_updated_by")
    private String lastUpdatedBy;

    @Column(name = "last_updated_at")
    private Instant lastUpdatedAt;

    @Column(name = "current_step")
    private String currentStep;

    @Lob
    @Column(name = "publish_targets_json")
    private String publishTargetsJson;

    @Version
    @Column(name = "lock_version")
    private Long version;
}
