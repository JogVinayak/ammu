package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.MindMapStatus;
import com.learning.mindmap_service.model.enums.MindMapVisibility;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MindMapResponse {
    private UUID mindMapId;
    private String tenantId;
    private String title;
    private String description;
    private String subject;
    private String grade;
    private List<String> tags;
    private MindMapStatus status;
    private MindMapVisibility visibility;
    private UUID createdBy;
    private UUID updatedBy;
    private Instant createdAt;
    private Instant updatedAt;
    private UUID publishedVersionId;
}
