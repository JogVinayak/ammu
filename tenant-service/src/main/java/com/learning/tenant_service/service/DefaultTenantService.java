package com.learning.tenant_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.tenant_service.exception.ResourceNotFoundException;
import com.learning.tenant_service.model.dto.CreateTenantRequest;
import com.learning.tenant_service.model.dto.DomainMappingRequest;
import com.learning.tenant_service.model.dto.DomainMappingResponse;
import com.learning.tenant_service.model.dto.PolicySnapshot;
import com.learning.tenant_service.model.dto.ResolveTenantResponse;
import com.learning.tenant_service.model.dto.TenantBrandingDto;
import com.learning.tenant_service.model.dto.TenantPolicyDto;
import com.learning.tenant_service.model.dto.TenantResponse;
import com.learning.tenant_service.model.dto.UpdateTenantRequest;
import com.learning.tenant_service.model.entity.Tenant;
import com.learning.tenant_service.model.entity.TenantBranding;
import com.learning.tenant_service.model.entity.TenantDomainMapping;
import com.learning.tenant_service.model.entity.TenantPolicy;
import com.learning.tenant_service.model.enums.AuthMethod;
import com.learning.tenant_service.model.enums.TenantStatus;
import com.learning.tenant_service.repository.TenantBrandingRepository;
import com.learning.tenant_service.repository.TenantDomainMappingRepository;
import com.learning.tenant_service.repository.TenantPolicyRepository;
import com.learning.tenant_service.repository.TenantRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultTenantService implements TenantService {
    private static final int DEFAULT_SESSION_MAX_DAYS = 30;
    private static final Set<AuthMethod> DEFAULT_AUTH_METHODS =
            Set.of(AuthMethod.PASSWORD, AuthMethod.OTP_SMS);
    private static final Pattern TENANT_KEY_PATTERN =
            Pattern.compile("^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$");

    private final TenantRepository tenantRepository;
    private final TenantPolicyRepository policyRepository;
    private final TenantBrandingRepository brandingRepository;
    private final TenantDomainMappingRepository domainRepository;
    private final ObjectMapper objectMapper;

    public DefaultTenantService(
            TenantRepository tenantRepository,
            TenantPolicyRepository policyRepository,
            TenantBrandingRepository brandingRepository,
            TenantDomainMappingRepository domainRepository,
            ObjectMapper objectMapper) {
        this.tenantRepository = tenantRepository;
        this.policyRepository = policyRepository;
        this.brandingRepository = brandingRepository;
        this.domainRepository = domainRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    @Transactional
    public TenantResponse createTenant(CreateTenantRequest request, String createdBy) {
        String tenantKey = normalizeTenantKey(request.getTenantKey());
        if (tenantRepository.existsByTenantKey(tenantKey)) {
            throw new IllegalStateException("Tenant key already exists");
        }

        Instant now = Instant.now();
        Tenant tenant = new Tenant();
        tenant.setId(UUID.randomUUID());
        tenant.setTenantKey(tenantKey);
        tenant.setName(request.getName());
        tenant.setStatus(TenantStatus.ACTIVE);
        tenant.setCreatedAt(now);
        tenant.setCreatedBy(createdBy);
        tenant.setUpdatedAt(now);
        tenant.setUpdatedBy(createdBy);
        tenantRepository.save(tenant);

        TenantPolicy policy = new TenantPolicy();
        policy.setId(UUID.randomUUID());
        policy.setTenantId(tenant.getId());
        policy.setCreatedAt(now);
        policy.setUpdatedAt(now);
        applyPolicyForCreate(policy, request.getPolicy());
        policyRepository.save(policy);

        TenantBranding branding = new TenantBranding();
        branding.setId(UUID.randomUUID());
        branding.setTenantId(tenant.getId());
        branding.setCreatedAt(now);
        branding.setUpdatedAt(now);
        if (request.getBranding() != null) {
            applyBrandingDto(branding, request.getBranding());
        }
        brandingRepository.save(branding);

        return toTenantResponse(tenant);
    }

    @Override
    @Transactional(readOnly = true)
    public List<TenantResponse> getTenants() {
        return tenantRepository.findAll().stream().map(this::toTenantResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public TenantResponse getTenant(UUID tenantId) {
        return toTenantResponse(getTenantEntity(tenantId));
    }

    @Override
    @Transactional
    public TenantResponse updateTenant(UUID tenantId, UpdateTenantRequest request, String updatedBy) {
        Tenant tenant = getTenantEntity(tenantId);
        if (request.getName() != null) {
            tenant.setName(request.getName());
        }
        if (request.getStatus() != null) {
            tenant.setStatus(request.getStatus());
        }
        tenant.setUpdatedAt(Instant.now());
        tenant.setUpdatedBy(updatedBy);
        return toTenantResponse(tenantRepository.save(tenant));
    }

    @Override
    @Transactional
    public TenantResponse suspendTenant(UUID tenantId, String updatedBy) {
        return updateStatus(tenantId, TenantStatus.SUSPENDED, updatedBy);
    }

    @Override
    @Transactional
    public TenantResponse activateTenant(UUID tenantId, String updatedBy) {
        return updateStatus(tenantId, TenantStatus.ACTIVE, updatedBy);
    }

    @Override
    @Transactional
    public TenantResponse deleteTenant(UUID tenantId, String updatedBy) {
        return updateStatus(tenantId, TenantStatus.DELETED, updatedBy);
    }

    @Override
    @Transactional(readOnly = true)
    public TenantPolicyDto getPolicy(UUID tenantId) {
        TenantPolicy policy = policyRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant policy not found"));
        return toPolicyDto(policy);
    }

    @Override
    @Transactional
    public TenantPolicyDto updatePolicy(UUID tenantId, TenantPolicyDto request, String updatedBy) {
        getTenantEntity(tenantId);
        Instant now = Instant.now();
        TenantPolicy policy = policyRepository.findByTenantId(tenantId)
                .orElseGet(() -> {
                    TenantPolicy created = new TenantPolicy();
                    created.setId(UUID.randomUUID());
                    created.setTenantId(tenantId);
                    created.setCreatedAt(now);
                    return created;
                });
        applyPolicyForUpdate(policy, request);
        policy.setUpdatedAt(now);
        policyRepository.save(policy);
        return toPolicyDto(policy);
    }

    @Override
    @Transactional(readOnly = true)
    public TenantBrandingDto getBranding(UUID tenantId) {
        TenantBranding branding = brandingRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant branding not found"));
        return toBrandingDto(branding);
    }

    @Override
    @Transactional
    public TenantBrandingDto updateBranding(UUID tenantId, TenantBrandingDto request, String updatedBy) {
        getTenantEntity(tenantId);
        Instant now = Instant.now();
        TenantBranding branding = brandingRepository.findByTenantId(tenantId)
                .orElseGet(() -> {
                    TenantBranding created = new TenantBranding();
                    created.setId(UUID.randomUUID());
                    created.setTenantId(tenantId);
                    created.setCreatedAt(now);
                    return created;
                });
        applyBrandingDto(branding, request);
        branding.setUpdatedAt(now);
        brandingRepository.save(branding);
        return toBrandingDto(branding);
    }

    @Override
    @Transactional
    public DomainMappingResponse addDomainMapping(UUID tenantId, DomainMappingRequest request, String createdBy) {
        getTenantEntity(tenantId);
        String hostname = normalizeHostname(request.getHostname());
        if (domainRepository.findByHostname(hostname).isPresent()) {
            throw new IllegalStateException("Hostname already mapped");
        }

        Instant now = Instant.now();
        TenantDomainMapping mapping = new TenantDomainMapping();
        mapping.setId(UUID.randomUUID());
        mapping.setTenantId(tenantId);
        mapping.setHostname(hostname);
        mapping.setType(request.getType());
        mapping.setVerified(false);
        mapping.setCreatedAt(now);
        mapping.setUpdatedAt(now);
        domainRepository.save(mapping);
        return toDomainMappingResponse(mapping);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DomainMappingResponse> getDomainMappings(UUID tenantId) {
        getTenantEntity(tenantId);
        return domainRepository.findByTenantId(tenantId).stream()
                .map(this::toDomainMappingResponse)
                .toList();
    }

    @Override
    @Transactional
    public DomainMappingResponse verifyDomainMapping(UUID tenantId, UUID domainId, String updatedBy) {
        TenantDomainMapping mapping = getDomainMapping(tenantId, domainId);
        mapping.setVerified(true);
        mapping.setUpdatedAt(Instant.now());
        domainRepository.save(mapping);
        return toDomainMappingResponse(mapping);
    }

    @Override
    @Transactional
    public void deleteDomainMapping(UUID tenantId, UUID domainId) {
        TenantDomainMapping mapping = getDomainMapping(tenantId, domainId);
        domainRepository.delete(mapping);
    }

    @Override
    @Transactional(readOnly = true)
    public ResolveTenantResponse resolveTenantByTenantKey(String tenantKey) {
        String normalized = normalizeTenantKey(tenantKey);
        Tenant tenant = tenantRepository.findByTenantKey(normalized)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found"));
        TenantPolicy policy = policyRepository.findByTenantId(tenant.getId()).orElse(null);
        return toResolveResponse(tenant, policy);
    }

    @Override
    @Transactional(readOnly = true)
    public ResolveTenantResponse resolveTenantByHostname(String hostname) {
        String normalized = normalizeHostname(hostname);
        TenantDomainMapping mapping = domainRepository.findByHostname(normalized)
                .orElseThrow(() -> new ResourceNotFoundException("Domain mapping not found"));
        Tenant tenant = getTenantEntity(mapping.getTenantId());
        TenantPolicy policy = policyRepository.findByTenantId(tenant.getId()).orElse(null);
        return toResolveResponse(tenant, policy);
    }

    private Tenant getTenantEntity(UUID tenantId) {
        return tenantRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Tenant not found"));
    }

    private TenantDomainMapping getDomainMapping(UUID tenantId, UUID domainId) {
        TenantDomainMapping mapping = domainRepository.findById(domainId)
                .orElseThrow(() -> new ResourceNotFoundException("Domain mapping not found"));
        if (!mapping.getTenantId().equals(tenantId)) {
            throw new ResourceNotFoundException("Domain mapping not found");
        }
        return mapping;
    }

    private TenantResponse updateStatus(UUID tenantId, TenantStatus status, String updatedBy) {
        Tenant tenant = getTenantEntity(tenantId);
        tenant.setStatus(status);
        tenant.setUpdatedAt(Instant.now());
        tenant.setUpdatedBy(updatedBy);
        return toTenantResponse(tenantRepository.save(tenant));
    }

    private TenantResponse toTenantResponse(Tenant tenant) {
        return new TenantResponse(
                tenant.getId(),
                tenant.getTenantKey(),
                tenant.getName(),
                tenant.getStatus(),
                tenant.getCreatedAt(),
                tenant.getUpdatedAt());
    }

    private TenantPolicyDto toPolicyDto(TenantPolicy policy) {
        TenantPolicyDto dto = new TenantPolicyDto();
        dto.setAllowSelfSignup(policy.isAllowSelfSignup());
        dto.setRequireAdminApproval(policy.isRequireAdminApproval());
        dto.setAllowedAuthMethods(toAuthMethodStrings(policy.getAllowedAuthMethods()));
        dto.setAllowedSignupDomains(policy.getAllowedSignupDomains());
        dto.setSessionMaxDays(policy.getSessionMaxDays());
        dto.setQuietHoursStart(policy.getQuietHoursStart());
        dto.setQuietHoursEnd(policy.getQuietHoursEnd());
        dto.setExtra(deserializeExtra(policy.getExtra()));
        return dto;
    }

    private TenantBrandingDto toBrandingDto(TenantBranding branding) {
        TenantBrandingDto dto = new TenantBrandingDto();
        dto.setDisplayName(branding.getDisplayName());
        dto.setLogoUrl(branding.getLogoUrl());
        dto.setPrimaryColor(branding.getPrimaryColor());
        dto.setAccentColor(branding.getAccentColor());
        return dto;
    }

    private DomainMappingResponse toDomainMappingResponse(TenantDomainMapping mapping) {
        return new DomainMappingResponse(
                mapping.getId(),
                mapping.getTenantId(),
                mapping.getHostname(),
                mapping.getType(),
                mapping.isVerified(),
                mapping.getCreatedAt(),
                mapping.getUpdatedAt());
    }

    private ResolveTenantResponse toResolveResponse(Tenant tenant, TenantPolicy policy) {
        PolicySnapshot snapshot = null;
        if (policy != null) {
            snapshot = new PolicySnapshot(
                    policy.isAllowSelfSignup(),
                    policy.isRequireAdminApproval(),
                    toAuthMethodStrings(policy.getAllowedAuthMethods()),
                    policy.getSessionMaxDays());
        }
        return new ResolveTenantResponse(
                tenant.getId(),
                tenant.getTenantKey(),
                tenant.getName(),
                tenant.getStatus(),
                snapshot);
    }

    private void applyPolicyForCreate(TenantPolicy policy, TenantPolicyDto dto) {
        if (dto == null) {
            policy.setAllowSelfSignup(false);
            policy.setRequireAdminApproval(true);
            policy.setAllowedAuthMethods(new LinkedHashSet<>(DEFAULT_AUTH_METHODS));
            policy.setSessionMaxDays(DEFAULT_SESSION_MAX_DAYS);
            return;
        }
        applyPolicyForUpdate(policy, dto);
        if (policy.getAllowedAuthMethods() == null || policy.getAllowedAuthMethods().isEmpty()) {
            policy.setAllowedAuthMethods(new LinkedHashSet<>(DEFAULT_AUTH_METHODS));
        }
        if (policy.getSessionMaxDays() == null) {
            policy.setSessionMaxDays(DEFAULT_SESSION_MAX_DAYS);
        }
        if (dto.getRequireAdminApproval() == null) {
            policy.setRequireAdminApproval(true);
        }
    }

    private void applyPolicyForUpdate(TenantPolicy policy, TenantPolicyDto dto) {
        if (dto.getAllowSelfSignup() != null) {
            policy.setAllowSelfSignup(dto.getAllowSelfSignup());
        }
        if (dto.getRequireAdminApproval() != null) {
            policy.setRequireAdminApproval(dto.getRequireAdminApproval());
        }
        if (dto.getAllowedAuthMethods() != null) {
            policy.setAllowedAuthMethods(toAuthMethods(dto.getAllowedAuthMethods()));
        }
        if (dto.getAllowedSignupDomains() != null) {
            policy.setAllowedSignupDomains(dto.getAllowedSignupDomains());
        }
        if (dto.getSessionMaxDays() != null) {
            policy.setSessionMaxDays(dto.getSessionMaxDays());
        }
        if (dto.getQuietHoursStart() != null) {
            policy.setQuietHoursStart(dto.getQuietHoursStart());
        }
        if (dto.getQuietHoursEnd() != null) {
            policy.setQuietHoursEnd(dto.getQuietHoursEnd());
        }
        if (dto.getExtra() != null) {
            policy.setExtra(serializeExtra(dto.getExtra()));
        }
    }

    private void applyBrandingDto(TenantBranding branding, TenantBrandingDto dto) {
        if (dto == null) {
            return;
        }
        branding.setDisplayName(dto.getDisplayName());
        branding.setLogoUrl(dto.getLogoUrl());
        branding.setPrimaryColor(dto.getPrimaryColor());
        branding.setAccentColor(dto.getAccentColor());
    }

    private Set<AuthMethod> toAuthMethods(List<String> methods) {
        if (methods == null) {
            return null;
        }
        Set<AuthMethod> results = new LinkedHashSet<>();
        for (String method : methods) {
            if (method == null || method.isBlank()) {
                continue;
            }
            results.add(AuthMethod.valueOf(method.trim().toUpperCase(Locale.ROOT)));
        }
        return results;
    }

    private List<String> toAuthMethodStrings(Set<AuthMethod> methods) {
        if (methods == null) {
            return List.of();
        }
        List<String> results = new ArrayList<>();
        for (AuthMethod method : methods) {
            results.add(method.name());
        }
        return results;
    }

    private String normalizeTenantKey(String tenantKey) {
        if (tenantKey == null || tenantKey.isBlank()) {
            throw new IllegalArgumentException("tenantKey is required");
        }
        String normalized = tenantKey.trim().toLowerCase(Locale.ROOT);
        if (!TENANT_KEY_PATTERN.matcher(normalized).matches()) {
            throw new IllegalArgumentException("tenantKey must be 3-50 chars, lowercase, and dash-separated");
        }
        return normalized;
    }

    private String normalizeHostname(String hostname) {
        if (hostname == null || hostname.isBlank()) {
            throw new IllegalArgumentException("hostname is required");
        }
        return hostname.trim().toLowerCase(Locale.ROOT);
    }

    private String serializeExtra(Map<String, Object> extra) {
        if (extra == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(extra);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Unable to serialize policy extras", e);
        }
    }

    private Map<String, Object> deserializeExtra(String extra) {
        if (extra == null || extra.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(extra, Map.class);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Unable to deserialize policy extras", e);
        }
    }
}
