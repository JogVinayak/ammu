package com.learning.user_profile_service.model.entity;

import com.learning.user_profile_service.model.enums.ConceptMasteryState;
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
        name = "student_concept_progress",
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_student_concept_progress_tenant_user_note",
                    columnNames = {"tenant_id", "user_id", "note_id"})
        },
        indexes = {
            @Index(name = "idx_student_concept_progress_tenant_user",
                   columnList = "tenant_id,user_id"),
            @Index(name = "idx_student_concept_progress_note",
                   columnList = "note_id"),
            @Index(name = "idx_student_concept_progress_mastery_state",
                   columnList = "tenant_id,user_id,mastery_state"),
            @Index(name = "idx_student_concept_progress_last_reviewed",
                   columnList = "tenant_id,user_id,last_reviewed_at")
        })
@Getter
@Setter
@NoArgsConstructor
public class StudentConceptProgress {

    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Enumerated(EnumType.STRING)
    @Column(name = "mastery_state", length = 50)
    private ConceptMasteryState masteryState = ConceptMasteryState.INITIAL;

    @Column(name = "memory_strength")
    private Double memoryStrength = 1.0;

    @Column(name = "last_exam_score")
    private Integer lastExamScore;

    @Column(name = "last_exam_passed_at")
    private Instant lastExamPassedAt;

    @Column(name = "total_exam_attempts")
    private Integer totalExamAttempts = 0;

    @Column(name = "passed_exam_count")
    private Integer passedExamCount = 0;

    @Column(name = "total_flashcards_reviewed")
    private Integer totalFlashcardsReviewed = 0;

    @Column(name = "total_reading_sessions")
    private Integer totalReadingSessions = 0;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;

    @Column(name = "mastery_achieved_at")
    private Instant masteryAchievedAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
