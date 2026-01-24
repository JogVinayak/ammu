package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.CreateTenantRequest;
import com.learning.tenant_service.model.dto.TenantResponse;
import com.learning.tenant_service.model.dto.UpdateTenantRequest;
import com.learning.tenant_service.service.TenantService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/tenants")
public class TenantController {
    private final TenantService tenantService;

    public TenantController(TenantService tenantService) {
        this.tenantService = tenantService;
    }

    @PostMapping
    public TenantResponse createTenant(
            @Valid @RequestBody CreateTenantRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.createTenant(request, userId);
    }

    @GetMapping
    public List<TenantResponse> getTenants() {
        return tenantService.getTenants();
    }

    @GetMapping("/{tenantId}")
    public TenantResponse getTenant(@PathVariable UUID tenantId) {
        return tenantService.getTenant(tenantId);
    }

    @PutMapping("/{tenantId}")
    public TenantResponse updateTenant(
            @PathVariable UUID tenantId,
            @RequestBody UpdateTenantRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.updateTenant(tenantId, request, userId);
    }

    @PostMapping("/{tenantId}/suspend")
    public TenantResponse suspendTenant(
            @PathVariable UUID tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.suspendTenant(tenantId, userId);
    }

    @PostMapping("/{tenantId}/activate")
    public TenantResponse activateTenant(
            @PathVariable UUID tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.activateTenant(tenantId, userId);
    }

    @DeleteMapping("/{tenantId}")
    public void deleteTenant(
            @PathVariable UUID tenantId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        tenantService.deleteTenant(tenantId, userId);
    }
}
