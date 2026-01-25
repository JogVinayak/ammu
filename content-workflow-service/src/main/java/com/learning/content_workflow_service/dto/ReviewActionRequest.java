package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReviewActionRequest {
    @Size(max = 2000)
    private String comment;
}
