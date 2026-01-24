package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.dto.CreateRoleRequest;
import com.learning.role_permission_service.dto.UpdateRoleRequest;
import com.learning.role_permission_service.entity.RoleEntity;

public interface RoleService {
	RoleEntity createRole(Long tenantId, CreateRoleRequest request, String createdBy);

	RoleEntity updateRole(Long tenantId, Long roleId, UpdateRoleRequest request, String updatedBy);

	RoleEntity getRole(Long tenantId, Long roleId);

	List<RoleEntity> getRoles(Long tenantId);

	void deleteRole(Long tenantId, Long roleId);
}
