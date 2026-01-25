package com.learning.notes_service.model.dto;

import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class UpdateNoteRequest {
    private String title;
    private String summary;
    private List<String> tags;
    private NoteScopeType scopeType;
    private UUID scopeId;
    private NoteStatus status;
    private UUID updatedBy;
}
