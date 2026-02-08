package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class McqResponse {
    private UUID id;
    private UUID noteId;
    private String questionText;
    private String optionsJson;
    private String difficulty;
    private String explanation;
    private Integer position;
    private UUID createdBy;
    private Instant createdAt;
    private Instant updatedAt;
}
