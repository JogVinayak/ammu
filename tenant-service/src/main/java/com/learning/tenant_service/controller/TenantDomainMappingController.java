package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.DomainMappingRequest;
import com.learning.tenant_service.model.dto.DomainMappingResponse;
import com.learning.tenant_service.service.TenantService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/tenants/{tenantId}/domains")
public class TenantDomainMappingController {
    private final TenantService tenantService;

    public TenantDomainMappingController(TenantService tenantService) {
        this.tenantService = tenantService;
    }

    @PostMapping
    public DomainMappingResponse addDomainMapping(
            @PathVariable UUID tenantId,
            @Valid @RequestBody DomainMappingRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.addDomainMapping(tenantId, request, userId);
    }

    @GetMapping
    public List<DomainMappingResponse> getDomainMappings(@PathVariable UUID tenantId) {
        return tenantService.getDomainMappings(tenantId);
    }

    @DeleteMapping("/{domainId}")
    public void deleteDomainMapping(
            @PathVariable UUID tenantId,
            @PathVariable UUID domainId) {
        tenantService.deleteDomainMapping(tenantId, domainId);
    }

    @PostMapping("/{domainId}/verify")
    public DomainMappingResponse verifyDomainMapping(
            @PathVariable UUID tenantId,
            @PathVariable UUID domainId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return tenantService.verifyDomainMapping(tenantId, domainId, userId);
    }
}
