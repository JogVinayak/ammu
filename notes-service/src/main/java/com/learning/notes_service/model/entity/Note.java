package com.learning.notes_service.model.entity;

import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
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
        name = "notes",
        indexes = {
            @Index(name = "idx_notes_tenant_status", columnList = "tenant_id,status"),
            @Index(name = "idx_notes_tenant_created_by", columnList = "tenant_id,created_by"),
            @Index(name = "idx_notes_tenant_updated_at", columnList = "tenant_id,updated_at")
        })
@Getter
@Setter
@NoArgsConstructor
public class Note {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(length = 2000)
    private String summary;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NoteStatus status;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(name = "latest_version_id")
    private UUID latestVersionId;

    @Column(name = "latest_published_version_id")
    private UUID latestPublishedVersionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type")
    private NoteScopeType scopeType;

    @Column(name = "scope_id")
    private UUID scopeId;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;
}
