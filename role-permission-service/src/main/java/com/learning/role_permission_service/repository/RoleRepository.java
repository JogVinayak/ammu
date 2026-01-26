package com.learning.role_permission_service.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.RoleEntity;

public interface RoleRepository extends JpaRepository<RoleEntity, Long> {
	List<RoleEntity> findByTenantId(String tenantId);

	Optional<RoleEntity> findByIdAndTenantId(Long id, String tenantId);

	boolean existsByTenantIdAndName(String tenantId, String name);
}
