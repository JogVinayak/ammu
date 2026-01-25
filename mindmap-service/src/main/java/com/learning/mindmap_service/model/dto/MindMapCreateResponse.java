package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.MindMapStatus;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MindMapCreateResponse {
    private UUID mindMapId;
    private MindMapStatus status;
}
