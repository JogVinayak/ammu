package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.dto.CreateRoleRequest;
import com.learning.role_permission_service.dto.UpdateRoleRequest;
import com.learning.role_permission_service.entity.RoleEntity;

public interface RoleService {
	RoleEntity createRole(String tenantId, CreateRoleRequest request, String createdBy);

	RoleEntity updateRole(String tenantId, Long roleId, UpdateRoleRequest request, String updatedBy);

	RoleEntity getRole(String tenantId, Long roleId);

	List<RoleEntity> getRoles(String tenantId);

	void deleteRole(String tenantId, Long roleId);
}
