package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.DomainType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class DomainMappingRequest {
    @NotBlank
    private String hostname;

    @NotNull
    private DomainType type;
}
