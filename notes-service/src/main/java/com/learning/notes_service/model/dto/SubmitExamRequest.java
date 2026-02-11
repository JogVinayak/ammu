package com.learning.notes_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SubmitExamRequest {
    private UUID studentId;
    private List<AnswerItem> answers;

    @Getter
    @Setter
    @NoArgsConstructor
    public static class AnswerItem {
        private UUID mcqId;
        private Integer selectedOptionIndex;
    }
}
