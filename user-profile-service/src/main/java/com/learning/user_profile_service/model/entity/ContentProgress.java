package com.learning.user_profile_service.model.entity;

import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.ProgressStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "content_progress")
@Getter
@Setter
@NoArgsConstructor
public class ContentProgress {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "content_id", nullable = false)
    private UUID contentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "content_type", nullable = false)
    private ContentType contentType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private ProgressStatus status = ProgressStatus.NOT_STARTED;

    @Column(name = "progress_percent")
    private Integer progressPercent = 0;

    @Column(name = "score", precision = 5, scale = 2)
    private BigDecimal score;

    @Column(name = "attempts")
    private Integer attempts = 0;

    @Column(name = "time_spent_seconds")
    private Long timeSpentSeconds = 0L;

    @Column(name = "last_position")
    private String lastPosition;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
