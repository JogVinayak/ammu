package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.DomainType;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DomainMappingResponse {
    private UUID id;
    private UUID tenantId;
    private String hostname;
    private DomainType type;
    private boolean verified;
    private Instant createdAt;
    private Instant updatedAt;
}
