package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.TenantStatus;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateTenantRequest {
    private String name;
    private TenantStatus status;
}
