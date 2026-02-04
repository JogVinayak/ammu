package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import lombok.Data;

@Data
public class ReleaseContentRequest {
    @NotEmpty(message = "Content IDs are required")
    private List<String> contentIds;

    @NotEmpty(message = "Class IDs are required")
    private List<String> classIds;

    @NotNull(message = "Content type is required")
    private String contentType; // "note" or "mindmap"
}
