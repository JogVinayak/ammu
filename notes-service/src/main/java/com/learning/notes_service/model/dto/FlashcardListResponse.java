package com.learning.notes_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class FlashcardListResponse {
    private UUID noteId;
    private List<FlashcardResponse> items;
    private int total;
}
