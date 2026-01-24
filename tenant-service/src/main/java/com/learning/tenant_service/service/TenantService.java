package com.learning.tenant_service.service;

import com.learning.tenant_service.model.dto.CreateTenantRequest;
import com.learning.tenant_service.model.dto.DomainMappingRequest;
import com.learning.tenant_service.model.dto.DomainMappingResponse;
import com.learning.tenant_service.model.dto.ResolveTenantResponse;
import com.learning.tenant_service.model.dto.TenantBrandingDto;
import com.learning.tenant_service.model.dto.TenantPolicyDto;
import com.learning.tenant_service.model.dto.TenantResponse;
import com.learning.tenant_service.model.dto.UpdateTenantRequest;
import java.util.List;
import java.util.UUID;

public interface TenantService {
    TenantResponse createTenant(CreateTenantRequest request, String createdBy);

    List<TenantResponse> getTenants();

    TenantResponse getTenant(UUID tenantId);

    TenantResponse updateTenant(UUID tenantId, UpdateTenantRequest request, String updatedBy);

    TenantResponse suspendTenant(UUID tenantId, String updatedBy);

    TenantResponse activateTenant(UUID tenantId, String updatedBy);

    TenantResponse deleteTenant(UUID tenantId, String updatedBy);

    TenantPolicyDto getPolicy(UUID tenantId);

    TenantPolicyDto updatePolicy(UUID tenantId, TenantPolicyDto request, String updatedBy);

    TenantBrandingDto getBranding(UUID tenantId);

    TenantBrandingDto updateBranding(UUID tenantId, TenantBrandingDto request, String updatedBy);

    DomainMappingResponse addDomainMapping(UUID tenantId, DomainMappingRequest request, String createdBy);

    List<DomainMappingResponse> getDomainMappings(UUID tenantId);

    DomainMappingResponse verifyDomainMapping(UUID tenantId, UUID domainId, String updatedBy);

    void deleteDomainMapping(UUID tenantId, UUID domainId);

    ResolveTenantResponse resolveTenantByTenantKey(String tenantKey);

    ResolveTenantResponse resolveTenantByHostname(String hostname);
}
