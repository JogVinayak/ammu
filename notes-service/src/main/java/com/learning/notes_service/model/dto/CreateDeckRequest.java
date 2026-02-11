package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateDeckRequest {
    private String title;
    private String description;
    private Integer requiredMcqCount;
    private Integer requiredFlashcardCount;
    private Integer easyPct;
    private Integer mediumPct;
    private Integer hardPct;
    private UUID createdBy;
}
