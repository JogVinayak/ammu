package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.MasteryLevel;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class KnowledgeCoverageResponse {
    UUID id;
    UUID userId;
    UUID mindmapId;
    UUID nodeId;
    MasteryLevel masteryLevel;
    BigDecimal confidenceScore;
    Integer reviewCount;
    Integer correctCount;
    Instant lastReviewedAt;
    Instant nextReviewAt;
    Instant createdAt;
    Instant updatedAt;
}
