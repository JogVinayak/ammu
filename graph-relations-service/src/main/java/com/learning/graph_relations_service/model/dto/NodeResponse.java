package com.learning.graph_relations_service.model.dto;

import com.learning.graph_relations_service.model.enums.NodeType;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NodeResponse {
    private UUID id;
    private UUID tenantId;
    private UUID graphId;
    private NodeType nodeType;
    private String refService;
    private String refType;
    private UUID refId;
    private String label;
    private String meta;
    private Instant createdAt;
    private Instant updatedAt;
}
