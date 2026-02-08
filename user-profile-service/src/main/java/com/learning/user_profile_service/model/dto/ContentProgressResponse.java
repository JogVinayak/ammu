package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.ProgressStatus;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ContentProgressResponse {
    UUID id;
    UUID userId;
    UUID contentId;
    ContentType contentType;
    ProgressStatus status;
    Integer progressPercent;
    BigDecimal score;
    Integer attempts;
    Long timeSpentSeconds;
    String lastPosition;
    Instant startedAt;
    Instant completedAt;
    Instant createdAt;
    Instant updatedAt;
}
