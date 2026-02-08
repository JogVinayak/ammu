package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateMcqRequest {
    private String questionText;
    private String optionsJson;
    private String difficulty;
    private String explanation;
    private Integer position;
    private UUID createdBy;
}
