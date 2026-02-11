package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ExamAttemptSummaryResponse {
    private UUID noteId;
    private UUID studentId;
    private long totalAttempts;
    private long passedCount;
    private Integer bestScore;
    private Double averageScore;
    private Boolean hasPassed;
}
