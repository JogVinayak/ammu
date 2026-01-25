package com.learning.notes_service.model.dto;

import com.learning.notes_service.model.enums.NoteScopeType;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateNoteRequest {
    private UUID tenantId;
    private String title;
    private String summary;
    private String contentMd;
    private String changeSummary;
    private List<String> tags;
    private NoteScopeType scopeType;
    private UUID scopeId;
    private UUID createdBy;
}
