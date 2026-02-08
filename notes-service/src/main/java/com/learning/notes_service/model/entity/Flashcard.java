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
        name = "flashcards",
        indexes = {
            @Index(name = "idx_flashcards_tenant_note", columnList = "tenant_id,note_id")
        },
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_flashcard_position",
                    columnNames = {"tenant_id", "note_id", "position"})
        })
@Getter
@Setter
@NoArgsConstructor
public class Flashcard {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(name = "front_text", nullable = false, columnDefinition = "TEXT")
    private String frontText;

    @Column(name = "back_text", nullable = false, columnDefinition = "TEXT")
    private String backText;

    @Column(name = "difficulty", nullable = false, length = 16)
    private String difficulty;

    @Column(nullable = false)
    private Integer position;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
