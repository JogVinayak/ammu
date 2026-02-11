package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateAssignmentRequest {

    @NotNull(message = "Note ID is required")
    private UUID noteId;

    @NotNull(message = "Class ID is required")
    private UUID classId;

    @Size(max = 200, message = "Title must not exceed 200 characters")
    private String title;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    private Instant dueDate;

    private CycleConfig cycleConfig;
}
