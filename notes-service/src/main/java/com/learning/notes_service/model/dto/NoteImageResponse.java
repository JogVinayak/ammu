package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteImageResponse {
    private UUID id;
    private UUID noteId;
    private String fileName;
    private String contentType;
    private Long sizeBytes;
    private String imageUrl;
    private UUID createdBy;
    private Instant createdAt;
}
