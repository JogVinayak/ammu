package com.learning.recall_service.dto;

import com.learning.recall_service.model.RecallOption;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RecallAttemptRequest {
    @NotNull
    private UUID topicId;

    @NotNull
    private RecallOption option;

    private Instant occurredAt;

    private Integer timeSpentSeconds;
}
