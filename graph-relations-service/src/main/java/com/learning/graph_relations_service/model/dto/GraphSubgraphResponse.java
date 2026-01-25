package com.learning.graph_relations_service.model.dto;

import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class GraphSubgraphResponse {
    private List<NodeResponse> nodes;
    private List<EdgeResponse> edges;
}
