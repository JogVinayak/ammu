package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class UpdateMcqRequest {
    private String questionText;
    private String optionsJson;
    private String difficulty;
    private String explanation;
    private Integer position;
    private UUID updatedBy;
}
