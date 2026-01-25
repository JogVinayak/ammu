package com.learning.graph_relations_service.model.dto;

import com.learning.graph_relations_service.model.enums.GraphStatus;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class GraphUpdateRequest {
    private String name;
    private String description;
    private GraphStatus status;
}
