package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.TenantBranding;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantBrandingRepository extends JpaRepository<TenantBranding, UUID> {
    Optional<TenantBranding> findByTenantId(UUID tenantId);
}
