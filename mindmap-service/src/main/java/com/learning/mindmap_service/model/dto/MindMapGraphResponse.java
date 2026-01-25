package com.learning.mindmap_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MindMapGraphResponse {
    private UUID mindMapId;
    private String version;
    private List<NodeResponse> nodes;
    private List<EdgeResponse> edges;
}
