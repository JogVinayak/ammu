package com.learning.notes_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "note_tags",
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_note_tag",
                    columnNames = {"tenant_id", "note_id", "tag"})
        })
@Getter
@Setter
@NoArgsConstructor
public class NoteTag {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(nullable = false, length = 50)
    private String tag;

    @Column(name = "created_at")
    private Instant createdAt;
}
