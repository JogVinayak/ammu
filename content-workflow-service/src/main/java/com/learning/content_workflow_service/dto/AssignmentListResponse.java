package com.learning.content_workflow_service.dto;

import java.util.List;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AssignmentListResponse {
    List<AssignmentResponse> items;
    int page;
    int size;
    long totalElements;
    int totalPages;
}
