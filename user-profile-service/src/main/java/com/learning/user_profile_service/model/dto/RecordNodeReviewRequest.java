package com.learning.user_profile_service.model.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Data;

@Data
public class RecordNodeReviewRequest {
    @NotNull
    private UUID mindmapId;

    @NotNull
    private UUID nodeId;

    @NotNull
    private Boolean correct;

    private Integer confidenceRating;
}
