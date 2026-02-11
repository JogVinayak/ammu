package com.learning.user_profile_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "daily_activity",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_daily_activity_tenant_user_date",
            columnNames = {"tenant_id", "user_id", "activity_date"})
    },
    indexes = {
        @Index(name = "idx_daily_activity_tenant_user",
               columnList = "tenant_id,user_id"),
        @Index(name = "idx_daily_activity_tenant_user_date",
               columnList = "tenant_id,user_id,activity_date"),
        @Index(name = "idx_daily_activity_all_rings_closed",
               columnList = "tenant_id,user_id,all_rings_closed,activity_date")
    })
@Getter
@Setter
@NoArgsConstructor
public class DailyActivity {

    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "activity_date", nullable = false)
    private LocalDate activityDate;

    @Column(name = "reading_count")
    private Integer readingCount = 0;

    @Column(name = "flashcard_count")
    private Integer flashcardCount = 0;

    @Column(name = "exam_count")
    private Integer examCount = 0;

    @Column(name = "reading_ring_closed")
    private Boolean readingRingClosed = false;

    @Column(name = "flashcard_ring_closed")
    private Boolean flashcardRingClosed = false;

    @Column(name = "exam_ring_closed")
    private Boolean examRingClosed = false;

    @Column(name = "all_rings_closed")
    private Boolean allRingsClosed = false;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
