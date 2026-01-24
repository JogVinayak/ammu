package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.Tenant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantRepository extends JpaRepository<Tenant, UUID> {
    boolean existsByTenantKey(String tenantKey);

    Optional<Tenant> findByTenantKey(String tenantKey);
}
