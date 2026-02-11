package com.learning.tenant_service.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CreateClassRequest {
    @NotBlank
    private String name;

    private Integer gradeLevel;

    private String description;
}
