package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.dto.CreatePermissionRequest;
import com.learning.role_permission_service.dto.UpdatePermissionRequest;
import com.learning.role_permission_service.entity.PermissionEntity;

public interface PermissionService {
	PermissionEntity createPermission(CreatePermissionRequest request);

	PermissionEntity updatePermission(Long permissionId, UpdatePermissionRequest request);

	PermissionEntity getPermission(Long permissionId);

	PermissionEntity getPermissionByCode(String code);

	List<PermissionEntity> getPermissions();
}
