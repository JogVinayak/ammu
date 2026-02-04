package com.learning.auth_service.repository;

import com.learning.auth_service.model.entity.TenantMembership;
import com.learning.auth_service.model.enums.TenantMembershipStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TenantMembershipRepository extends JpaRepository<TenantMembership, UUID> {
    List<TenantMembership> findByUserId(UUID userId);
    List<TenantMembership> findByUserIdAndStatus(UUID userId, TenantMembershipStatus status);
    List<TenantMembership> findByTenantIdAndStatus(UUID tenantId, TenantMembershipStatus status);
}
