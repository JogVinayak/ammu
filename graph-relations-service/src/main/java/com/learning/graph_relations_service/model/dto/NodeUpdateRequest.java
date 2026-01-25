package com.learning.graph_relations_service.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NodeUpdateRequest {
    private String label;
    private String meta;
}
