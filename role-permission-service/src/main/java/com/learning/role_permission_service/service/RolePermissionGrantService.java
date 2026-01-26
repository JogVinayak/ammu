package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.dto.AssignPermissionsRequest;
import com.learning.role_permission_service.entity.RolePermissionGrantEntity;

public interface RolePermissionGrantService {
	RolePermissionGrantEntity createGrant(String tenantId, RolePermissionGrantEntity grant, String createdBy);

	List<RolePermissionGrantEntity> assignPermissions(String tenantId, AssignPermissionsRequest request, String createdBy);

	List<RolePermissionGrantEntity> getGrants(String tenantId, Long roleId);

	void deleteGrant(String tenantId, Long grantId);
}
