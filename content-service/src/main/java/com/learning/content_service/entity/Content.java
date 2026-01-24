package com.learning.content_service.entity;

import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import com.learning.content_service.enums.ContentVisibility;
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
        name = "contents",
        indexes = {
            @Index(name = "idx_content_tenant_type_status", columnList = "tenant_id,type,status"),
            @Index(name = "idx_content_tenant_topic", columnList = "tenant_id,topic_id"),
            @Index(name = "idx_content_tenant_module", columnList = "tenant_id,module_id"),
            @Index(name = "idx_content_tenant_title", columnList = "tenant_id,title")
        })
@Getter
@Setter
@NoArgsConstructor
public class Content {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ContentType type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ContentStatus status;

    @Column(name = "current_version", nullable = false)
    private Integer currentVersion;

    @Column(name = "latest_draft_version")
    private Integer latestDraftVersion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ContentVisibility visibility;

    @Column(name = "topic_id")
    private UUID topicId;

    @Column(name = "module_id")
    private UUID moduleId;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(nullable = false)
    private boolean deleted;
}
