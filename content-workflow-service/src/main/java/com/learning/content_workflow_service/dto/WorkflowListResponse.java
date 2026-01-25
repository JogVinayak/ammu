package com.learning.content_workflow_service.dto;

import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class WorkflowListResponse {
    private List<WorkflowResponse> items;
    private int page;
    private int size;
    private long total;
}
