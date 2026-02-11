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
        name = "exam_answers",
        indexes = {
            @Index(name = "idx_exam_answers_tenant_attempt",
                   columnList = "tenant_id,exam_attempt_id")
        },
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_exam_answer_attempt_mcq",
                    columnNames = {"tenant_id", "exam_attempt_id", "mcq_id"})
        })
@Getter
@Setter
@NoArgsConstructor
public class ExamAnswer {

    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "exam_attempt_id", nullable = false)
    private UUID examAttemptId;

    @Column(name = "mcq_id", nullable = false)
    private UUID mcqId;

    @Column(name = "selected_option_index", nullable = false)
    private Integer selectedOptionIndex;

    @Column(name = "correct", nullable = false)
    private Boolean correct;

    @Column(name = "answered_at", nullable = false)
    private Instant answeredAt;
}
