package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.TenantPolicyDto;
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
@RequestMapping("/v1/tenants/{tenantId}/policy")
public class TenantPolicyController {
    private final TenantService tenantService;

    public TenantPolicyController(TenantService tenantService) {
        this.tenantService = tenantService;
    }

    @GetMapping
    public TenantPolicyDto getPolicy(@PathVariable UUID tenantId) {
        return tenantService.getPolicy(tenantId);
    }

    @PutMapping
    public TenantPolicyDto updatePolicy(
            @PathVariable UUID tenantId,
            @Valid @RequestBody TenantPolicyDto request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.updatePolicy(tenantId, request, userId);
    }
}
