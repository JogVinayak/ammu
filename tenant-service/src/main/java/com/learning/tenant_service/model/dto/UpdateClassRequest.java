package com.learning.tenant_service.model.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateClassRequest {
    private String name;

    private Integer gradeLevel;

    private String description;
}
