package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.TenantStatus;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResolveTenantResponse {
    private UUID tenantId;
    private String tenantKey;
    private String name;
    private TenantStatus status;
    private PolicySnapshot policy;
}
