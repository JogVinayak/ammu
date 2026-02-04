package com.learning.recall_service.entity;

import com.learning.recall_service.model.RecallOption;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "recall_events")
@Getter
@Setter
@NoArgsConstructor
public class RecallEvent {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "topic_id", nullable = false)
    private UUID topicId;

    @Enumerated(EnumType.STRING)
    @Column(name = "option", nullable = false, length = 16)
    private RecallOption option;

    @Column(name = "time_spent_seconds")
    private Integer timeSpentSeconds;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Column(name = "calculated_interval_seconds", nullable = false)
    private long calculatedIntervalSeconds;

    @Column(name = "next_review_at", nullable = false)
    private Instant nextReviewAt;

    @Column(name = "meta")
    private String meta;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }
}
