package com.learning.mindmap_service.model.entity;

import com.learning.mindmap_service.model.enums.MindMapStatus;
import com.learning.mindmap_service.model.enums.MindMapVisibility;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "mind_maps",
        indexes = {
            @Index(name = "idx_mind_maps_tenant", columnList = "tenant_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class MindMap {
    @Id
    @Column(name = "mind_map_id")
    private UUID mindMapId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(length = 100)
    private String subject;

    @Column(length = 50)
    private String grade;

    @Column(name = "tags_json", columnDefinition = "jsonb")
    private String tagsJson;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MindMapStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MindMapVisibility visibility;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(name = "published_version_id")
    private UUID publishedVersionId;

    @Version
    @Column(name = "lock_version")
    private Long lockVersion;
}
