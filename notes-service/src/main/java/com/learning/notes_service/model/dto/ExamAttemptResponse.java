package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ExamAttemptResponse {
    private UUID id;
    private UUID noteId;
    private UUID deckId;
    private UUID studentId;
    private Integer totalQuestions;
    private Integer correctCount;
    private Integer scorePercent;
    private Boolean passed;
    private String status;
    private Instant startedAt;
    private Instant completedAt;
    private Instant createdAt;
    private List<ExamAnswerResponse> answers;
}
