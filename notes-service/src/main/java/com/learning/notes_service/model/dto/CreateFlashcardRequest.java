package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateFlashcardRequest {
    private String frontText;
    private String backText;
    private String difficulty;
    private Integer position;
    private UUID createdBy;
}
