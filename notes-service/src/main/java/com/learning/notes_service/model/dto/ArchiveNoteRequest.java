package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ArchiveNoteRequest {
    private UUID archivedBy;
    private String archiveReason;  // Optional reason for archiving
}
