package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.TenantPolicy;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantPolicyRepository extends JpaRepository<TenantPolicy, UUID> {
    Optional<TenantPolicy> findByTenantId(UUID tenantId);
}
