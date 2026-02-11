package com.learning.notes_service.model.entity;

import com.learning.notes_service.model.enums.DeckStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
        name = "decks",
        indexes = {
            @Index(name = "idx_decks_tenant_note", columnList = "tenant_id,note_id"),
            @Index(name = "idx_decks_tenant_status", columnList = "tenant_id,status")
        },
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_deck_tenant_note",
                    columnNames = {"tenant_id", "note_id"})
        })
@Getter
@Setter
@NoArgsConstructor
public class Deck {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private DeckStatus status;

    @Column(name = "required_mcq_count", nullable = false)
    private Integer requiredMcqCount;

    @Column(name = "required_flashcard_count", nullable = false)
    private Integer requiredFlashcardCount;

    @Column(name = "easy_pct", nullable = false)
    private Integer easyPct;

    @Column(name = "medium_pct", nullable = false)
    private Integer mediumPct;

    @Column(name = "hard_pct", nullable = false)
    private Integer hardPct;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
