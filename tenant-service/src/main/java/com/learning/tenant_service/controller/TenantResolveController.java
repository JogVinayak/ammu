package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.ResolveTenantResponse;
import com.learning.tenant_service.service.TenantService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/resolve")
public class TenantResolveController {
    private final TenantService tenantService;

    public TenantResolveController(TenantService tenantService) {
        this.tenantService = tenantService;
    }

    @GetMapping
    public ResolveTenantResponse resolve(
            @RequestParam(value = "tenantKey", required = false) String tenantKey,
            @RequestParam(value = "hostname", required = false) String hostname) {
        boolean hasTenantKey = tenantKey != null && !tenantKey.isBlank();
        boolean hasHostname = hostname != null && !hostname.isBlank();
        if (!hasTenantKey && !hasHostname) {
            throw new IllegalArgumentException("tenantKey or hostname is required");
        }
        if (hasTenantKey) {
            return tenantService.resolveTenantByTenantKey(tenantKey);
        }
        return tenantService.resolveTenantByHostname(hostname);
    }
}
