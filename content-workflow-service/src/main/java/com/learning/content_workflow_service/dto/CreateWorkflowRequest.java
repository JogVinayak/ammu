package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateWorkflowRequest {
    @NotBlank
    private String contentId;

    @NotBlank
    private String contentVersionId;

    @Size(max = 200)
    private String titleSnapshot;

    private PublishTargets publishTargets;
}
