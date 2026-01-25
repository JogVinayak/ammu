package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.EdgeRelation;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class UpsertEdgeRequest {
    @NotNull
    private UUID fromNodeId;

    @NotNull
    private UUID toNodeId;

    @NotNull
    private EdgeRelation relation;

    private Double weight;

    private Double strength;

    private Long ttlSeconds;
}
