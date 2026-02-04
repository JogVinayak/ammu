package com.learning.recall_service.entity;

import com.learning.recall_service.model.RecallOption;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "recall_schedule",
        indexes = {
            @Index(name = "idx_recall_schedule_due", columnList = "tenant_id,user_id,next_review_at"),
            @Index(name = "idx_recall_schedule_next_review", columnList = "next_review_at")
        })
@Getter
@Setter
@NoArgsConstructor
public class RecallSchedule {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "topic_id", nullable = false)
    private UUID topicId;

    @Enumerated(EnumType.STRING)
    @Column(name = "last_option", nullable = false, length = 16)
    private RecallOption lastOption;

    @Column(name = "interval_seconds", nullable = false)
    private long intervalSeconds;

    @Column(name = "next_review_at", nullable = false)
    private Instant nextReviewAt;

    @Column(name = "last_reviewed_at", nullable = false)
    private Instant lastReviewedAt;

    @Column(name = "last_notified_at")
    private Instant lastNotifiedAt;

    @Column(name = "reminder_count", nullable = false)
    private int reminderCount;

    @Column(name = "streak", nullable = false)
    private int streak;

    @Column(name = "ease_factor", nullable = false)
    private double easeFactor;

    @Column(name = "lapse_count", nullable = false)
    private int lapseCount;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }
}
