package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.NodeType;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NodeResponse {
    private UUID nodeId;
    private UUID mindMapId;
    private NodeType type;
    private String title;
    private String bodyMarkdown;
    private UUID contentId;
    private UUID contentVersionId;
    private Double posX;
    private Double posY;
    private String metaJson;
    private Instant createdAt;
    private Instant updatedAt;
}
