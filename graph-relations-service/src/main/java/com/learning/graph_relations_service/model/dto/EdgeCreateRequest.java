package com.learning.graph_relations_service.model.dto;

import com.learning.graph_relations_service.model.enums.RelationType;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class EdgeCreateRequest {
    private UUID tenantId;
    private UUID graphId;
    private UUID fromNodeId;
    private UUID toNodeId;
    private RelationType relationType;
    private boolean directed;
    private double strength;
    private int ttlHours;
    private String meta;
}
