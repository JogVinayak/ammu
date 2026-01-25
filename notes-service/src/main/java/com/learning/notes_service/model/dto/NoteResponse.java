package com.learning.notes_service.model.dto;

import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteResponse {
    private UUID id;
    private UUID tenantId;
    private String title;
    private String summary;
    private NoteStatus status;
    private UUID createdBy;
    private UUID updatedBy;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant publishedAt;
    private UUID latestVersionId;
    private UUID latestPublishedVersionId;
    private boolean deleted;
    private List<String> tags;
    private NoteScopeType scopeType;
    private UUID scopeId;
}
