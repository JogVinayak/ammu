package com.learning.mindmap_service.model.entity;

import com.learning.mindmap_service.model.enums.MindMapVersionStatus;
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
        name = "mind_map_versions",
        indexes = {
            @Index(name = "idx_mind_map_versions_map", columnList = "mind_map_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class MindMapVersion {
    @Id
    @Column(name = "mind_map_version_id")
    private UUID mindMapVersionId;

    @Column(name = "mind_map_id", nullable = false)
    private UUID mindMapId;

    @Column(name = "version_number", nullable = false)
    private Integer versionNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MindMapVersionStatus status;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at")
    private Instant createdAt;
}
