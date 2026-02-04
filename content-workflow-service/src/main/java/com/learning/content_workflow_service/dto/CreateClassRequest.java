package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Value;

@Value
public class CreateClassRequest {
    @NotBlank(message = "Class name is required")
    @Size(max = 100, message = "Class name must not exceed 100 characters")
    String name;

    @Size(max = 100, message = "Subject must not exceed 100 characters")
    String subject;

    @Size(max = 50, message = "Grade must not exceed 50 characters")
    String grade;

    @Size(max = 500, message = "Description must not exceed 500 characters")
    String description;
}
