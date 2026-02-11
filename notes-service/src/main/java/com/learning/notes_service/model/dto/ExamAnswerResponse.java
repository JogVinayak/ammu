package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ExamAnswerResponse {
    private UUID id;
    private UUID mcqId;
    private Integer selectedOptionIndex;
    private Boolean correct;
    private Instant answeredAt;
}
