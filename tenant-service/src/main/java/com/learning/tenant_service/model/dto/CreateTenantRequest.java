package com.learning.tenant_service.model.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CreateTenantRequest {
    @NotBlank
    @Pattern(regexp = "^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$")
    private String tenantKey;

    @NotBlank
    private String name;

    @Valid
    private TenantPolicyDto policy;

    @Valid
    private TenantBrandingDto branding;
}
