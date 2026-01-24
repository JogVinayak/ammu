package com.learning.tenant_service.model.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class TenantBrandingDto {
    private String displayName;
    private String logoUrl;
    private String primaryColor;
    private String accentColor;
}
