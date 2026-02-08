package com.learning.notes_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class BatchMcqsRequest {
    private List<McqItem> mcqs;
    private UUID createdBy;
    private boolean replaceAll;

    @Getter
    @Setter
    @NoArgsConstructor
    public static class McqItem {
        private UUID id;
        private String questionText;
        private String optionsJson;
        private String difficulty;
        private String explanation;
        private Integer position;
    }
}
