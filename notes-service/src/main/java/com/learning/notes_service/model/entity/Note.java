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

    // Review workflow fields
    @Column(name = "submitted_at")
    private Instant submittedAt;

    @Column(name = "submitted_by")
    private UUID submittedBy;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "reviewed_by")
    private UUID reviewedBy;

    @Column(name = "rejection_reason", length = 1000)
    private String rejectionReason;

    // Release fields (renamed from published)
    @Column(name = "released_at")
    private Instant releasedAt;

    @Column(name = "released_by")
    private UUID releasedBy;

    // Archive fields
    @Column(name = "archived_at")
    private Instant archivedAt;

    @Column(name = "archived_by")
    private UUID archivedBy;

    @Column(name = "archive_reason", length = 500)
    private String archiveReason;

    @Column(name = "latest_version_id")
    private UUID latestVersionId;

    @Column(name = "latest_released_version_id")
    private UUID latestReleasedVersionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type")
    private NoteScopeType scopeType;

    @Column(name = "scope_id")
    private UUID scopeId;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;
}
