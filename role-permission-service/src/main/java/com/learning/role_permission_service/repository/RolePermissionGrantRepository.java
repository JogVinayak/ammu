package com.learning.role_permission_service.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.RolePermissionGrantEntity;

public interface RolePermissionGrantRepository extends JpaRepository<RolePermissionGrantEntity, Long> {
	List<RolePermissionGrantEntity> findByTenantIdAndRoleId(String tenantId, Long roleId);

	List<RolePermissionGrantEntity> findByTenantIdAndRoleIdIn(String tenantId, Collection<Long> roleIds);

	List<RolePermissionGrantEntity> findByTenantIdAndRoleIdInAndPermissionCode(
			String tenantId,
			Collection<Long> roleIds,
			String permissionCode);

	Optional<RolePermissionGrantEntity> findByIdAndTenantId(Long id, String tenantId);
}
