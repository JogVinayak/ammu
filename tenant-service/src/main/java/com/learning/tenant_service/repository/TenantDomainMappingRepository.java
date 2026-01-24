package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.TenantDomainMapping;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantDomainMappingRepository extends JpaRepository<TenantDomainMapping, UUID> {
    List<TenantDomainMapping> findByTenantId(UUID tenantId);

    Optional<TenantDomainMapping> findByHostname(String hostname);
}
