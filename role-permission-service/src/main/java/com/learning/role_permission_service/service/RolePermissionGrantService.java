package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.dto.AssignPermissionsRequest;
import com.learning.role_permission_service.entity.RolePermissionGrantEntity;

public interface RolePermissionGrantService {
	RolePermissionGrantEntity createGrant(Long tenantId, RolePermissionGrantEntity grant, String createdBy);

	List<RolePermissionGrantEntity> assignPermissions(Long tenantId, AssignPermissionsRequest request, String createdBy);

	List<RolePermissionGrantEntity> getGrants(Long tenantId, Long roleId);

	void deleteGrant(Long tenantId, Long grantId);
}
