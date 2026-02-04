package com.learning.recall_service.dto;

import com.learning.recall_service.model.RecallOption;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RecallAttemptResponse {
    private UUID topicId;
    private RecallOption option;
    private long intervalSeconds;
    private Instant nextReviewAt;
    private int streak;
    private double easeFactor;
    private Instant lastReviewedAt;
}
