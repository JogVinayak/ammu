package com.learning.notes_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "mcqs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Mcq {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(name = "question_text", nullable = false, columnDefinition = "TEXT")
    private String questionText;

    @Column(name = "options_json", nullable = false, columnDefinition = "TEXT")
    private String optionsJson;

    @Column(name = "difficulty", nullable = false, length = 16)
    private String difficulty;

    @Column(name = "explanation", columnDefinition = "TEXT")
    private String explanation;

    @Column(name = "position", nullable = false)
    private Integer position;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
