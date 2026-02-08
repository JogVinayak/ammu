package com.learning.user_profile_service.model.entity;

import com.learning.user_profile_service.model.enums.MasteryLevel;
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
@Table(name = "knowledge_coverage")
@Getter
@Setter
@NoArgsConstructor
public class KnowledgeCoverage {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "mindmap_id", nullable = false)
    private UUID mindmapId;

    @Column(name = "node_id", nullable = false)
    private UUID nodeId;

    @Enumerated(EnumType.STRING)
    @Column(name = "mastery_level")
    private MasteryLevel masteryLevel = MasteryLevel.NOT_STARTED;

    @Column(name = "confidence_score", precision = 5, scale = 2)
    private BigDecimal confidenceScore;

    @Column(name = "review_count")
    private Integer reviewCount = 0;

    @Column(name = "correct_count")
    private Integer correctCount = 0;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;

    @Column(name = "next_review_at")
    private Instant nextReviewAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
