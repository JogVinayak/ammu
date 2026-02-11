package com.learning.notes_service.model.entity;

import com.learning.notes_service.model.enums.ExamAttemptStatus;
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
        name = "exam_attempts",
        indexes = {
            @Index(name = "idx_exam_attempts_tenant_note_student",
                   columnList = "tenant_id,note_id,student_id"),
            @Index(name = "idx_exam_attempts_tenant_deck",
                   columnList = "tenant_id,deck_id"),
            @Index(name = "idx_exam_attempts_tenant_status",
                   columnList = "tenant_id,status")
        })
@Getter
@Setter
@NoArgsConstructor
public class ExamAttempt {

    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(name = "deck_id", nullable = false)
    private UUID deckId;

    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    @Column(name = "total_questions", nullable = false)
    private Integer totalQuestions;

    @Column(name = "correct_count")
    private Integer correctCount;

    @Column(name = "score_percent")
    private Integer scorePercent;

    @Column(name = "passed")
    private Boolean passed;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private ExamAttemptStatus status;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
