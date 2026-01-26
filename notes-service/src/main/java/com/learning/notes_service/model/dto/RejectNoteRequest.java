package com.learning.notes_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class RejectNoteRequest {
    private UUID rejectedBy;
    private String rejectionReason;  // Feedback for revision
}
