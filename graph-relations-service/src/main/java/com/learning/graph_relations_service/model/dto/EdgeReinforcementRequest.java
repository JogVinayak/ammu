package com.learning.graph_relations_service.model.dto;

import com.learning.graph_relations_service.model.enums.EdgeSignalType;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class EdgeReinforcementRequest {
    private UUID graphId;
    private UUID edgeId;
    private UUID userId;
    private EdgeSignalType signalType;
    private Double signalValue;
    private Instant occurredAt;
}
