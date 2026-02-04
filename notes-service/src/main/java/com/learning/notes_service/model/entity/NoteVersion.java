package com.learning.notes_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "note_versions",
        indexes = {
            @Index(name = "idx_note_versions_tenant_note", columnList = "tenant_id,note_id")
        },
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_note_version_no",
                    columnNames = {"tenant_id", "note_id", "version_no"})
        })
@Getter
@Setter
@NoArgsConstructor
public class NoteVersion {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(name = "version_no", nullable = false)
    private Integer versionNo;

    @Column(name = "content_md", nullable = false)
    private String contentMd;

    @Column(name = "content_hash")
    private String contentHash;

    @Column(name = "content_guided_json")
    private String contentGuidedJson;

    @Column(name = "change_summary")
    private String changeSummary;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at")
    private Instant createdAt;
}
