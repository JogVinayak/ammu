package com.learning.mindmap_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReviewEdgeResponse {
    private UUID edgeId;
    private Double strength;
    private Long ttlSeconds;
    private Instant expiresAt;
}
