package com.learning.content_workflow_service.dto;

import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PublishWorkflowRequest {
    private Instant publishAt;
    private PublishTargets publishTargets;
}
