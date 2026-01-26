package com.learning.role_permission_service.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.AccessPolicyEntity;

public interface AccessPolicyRepository extends JpaRepository<AccessPolicyEntity, Long> {
	List<AccessPolicyEntity> findByTenantId(String tenantId);

	List<AccessPolicyEntity> findByTenantIdAndStatus(String tenantId, String status);

	Optional<AccessPolicyEntity> findByIdAndTenantId(Long id, String tenantId);
}
