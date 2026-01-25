package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.EdgeRelation;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class EdgeResponse {
    private UUID edgeId;
    private UUID mindMapId;
    private UUID fromNodeId;
    private UUID toNodeId;
    private EdgeRelation relation;
    private Double weight;
    private Double strength;
    private Long ttlSeconds;
    private Instant lastReviewedAt;
    private Instant expiresAt;
    private Instant createdAt;
    private Instant updatedAt;
}
