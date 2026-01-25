package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateNoteVersionRequest {
    private String contentMd;
    private String contentHash;
    private String changeSummary;
    private UUID createdBy;
}
