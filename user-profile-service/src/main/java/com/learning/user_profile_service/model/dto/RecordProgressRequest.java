package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.ProgressEventType;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;
import lombok.Data;

@Data
public class RecordProgressRequest {
    @NotNull
    private ProgressEventType eventType;

    @NotNull
    private UUID contentId;

    @NotNull
    private ContentType contentType;

    private Integer progressPercent;
    private BigDecimal score;
    private Long timeSpentSeconds;
    private String lastPosition;
    private Map<String, Object> eventData;
}
