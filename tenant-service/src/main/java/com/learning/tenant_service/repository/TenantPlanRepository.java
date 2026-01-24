package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.TenantPlan;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantPlanRepository extends JpaRepository<TenantPlan, UUID> {
    Optional<TenantPlan> findByTenantId(UUID tenantId);
}
