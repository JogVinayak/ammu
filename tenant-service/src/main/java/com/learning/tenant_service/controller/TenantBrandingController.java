package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.TenantBrandingDto;
import com.learning.tenant_service.service.TenantService;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/tenants/{tenantId}/branding")
public class TenantBrandingController {
    private final TenantService tenantService;

    public TenantBrandingController(TenantService tenantService) {
        this.tenantService = tenantService;
    }

    @GetMapping
    public TenantBrandingDto getBranding(@PathVariable UUID tenantId) {
        return tenantService.getBranding(tenantId);
    }

    @PutMapping
    public TenantBrandingDto updateBranding(
            @PathVariable UUID tenantId,
            @Valid @RequestBody TenantBrandingDto request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.updateBranding(tenantId, request, userId);
    }
}
