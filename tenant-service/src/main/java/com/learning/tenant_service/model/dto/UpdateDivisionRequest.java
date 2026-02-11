package com.learning.tenant_service.model.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateDivisionRequest {
    private String name;

    private String displayName;
}
