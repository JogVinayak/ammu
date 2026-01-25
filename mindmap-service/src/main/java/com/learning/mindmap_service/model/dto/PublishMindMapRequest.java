package com.learning.mindmap_service.model.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PublishMindMapRequest {
    @NotNull
    private PublishTargets publishTargets;
}
