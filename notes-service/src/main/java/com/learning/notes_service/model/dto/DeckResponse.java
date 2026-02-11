package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DeckResponse {
    private UUID id;
    private UUID noteId;
    private String title;
    private String description;
    private String status;
    private Integer requiredMcqCount;
    private Integer requiredFlashcardCount;
    private Integer easyPct;
    private Integer mediumPct;
    private Integer hardPct;
    private UUID createdBy;
    private UUID updatedBy;
    private Instant createdAt;
    private Instant updatedAt;
}
