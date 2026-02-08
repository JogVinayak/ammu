package com.learning.notes_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class BatchFlashcardsRequest {
    private List<FlashcardItem> flashcards;
    private UUID createdBy;
    private boolean replaceAll;

    @Getter
    @Setter
    @NoArgsConstructor
    public static class FlashcardItem {
        private UUID id;
        private String frontText;
        private String backText;
        private String difficulty;
        private Integer position;
    }
}
