package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.EdgeReviewResult;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReviewEdgeRequest {
    private String userId;

    @NotNull
    private EdgeReviewResult result;

    private Integer difficulty;

    private Integer timeSpentSeconds;
}
