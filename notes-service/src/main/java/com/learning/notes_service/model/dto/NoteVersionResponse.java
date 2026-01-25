package com.learning.notes_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteVersionResponse {
    private UUID id;
    private UUID tenantId;
    private UUID noteId;
    private int versionNo;
    private String contentMd;
    private String contentHash;
    private String changeSummary;
    private UUID createdBy;
    private Instant createdAt;
}
