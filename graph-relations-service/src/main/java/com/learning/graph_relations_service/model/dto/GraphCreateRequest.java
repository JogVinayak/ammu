package com.learning.graph_relations_service.model.dto;

import com.learning.graph_relations_service.model.enums.GraphScopeType;
import com.learning.graph_relations_service.model.enums.GraphStatus;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class GraphCreateRequest {
    private UUID tenantId;
    private GraphScopeType scopeType;
    private UUID scopeId;
    private String name;
    private String description;
    private GraphStatus status;
    private UUID createdBy;
}
