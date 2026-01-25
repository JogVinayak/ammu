package com.learning.notes_service.model.dto;

import com.learning.notes_service.model.enums.NoteStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteRenderResponse {
    private UUID noteId;
    private UUID versionId;
    private int versionNo;
    private String title;
    private String contentMd;
    private Instant publishedAt;
    private NoteStatus status;
}
