package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReleaseNoteRequest {
    private UUID versionId;    // Optional: specific version to release
    private UUID releasedBy;
}
