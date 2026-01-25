package com.learning.graph_relations_service.model.dto;

import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class EdgeUpdateRequest {
    private boolean directed;
    private double strength;
    private int ttlHours;
    private Instant lastReinforcedAt;
    private Instant lastReviewedAt;
    private String meta;
}
