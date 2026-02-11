package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DeckCompositionResponse {
    private UUID deckId;
    private UUID noteId;
    private String status;
    private boolean compositionMet;

    private CompositionDetail mcqs;
    private CompositionDetail flashcards;

    @Getter
    @Setter
    @NoArgsConstructor
    public static class CompositionDetail {
        private long totalRequired;
        private long totalActual;
        private boolean totalMet;

        private long easyRequired;
        private long easyActual;
        private boolean easyMet;

        private long mediumRequired;
        private long mediumActual;
        private boolean mediumMet;

        private long hardRequired;
        private long hardActual;
        private boolean hardMet;
    }
}
