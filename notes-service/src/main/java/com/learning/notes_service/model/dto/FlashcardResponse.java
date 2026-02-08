package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class FlashcardResponse {
    private UUID id;
    private UUID noteId;
    private String frontText;
    private String backText;
    private String difficulty;
    private Integer position;
    private UUID createdBy;
    private Instant createdAt;
    private Instant updatedAt;
}
