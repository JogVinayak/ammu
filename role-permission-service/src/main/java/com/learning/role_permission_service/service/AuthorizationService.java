package com.learning.role_permission_service.service;

import com.learning.role_permission_service.dto.PermissionCheckRequest;
import com.learning.role_permission_service.dto.PermissionCheckResult;

public interface AuthorizationService {
	PermissionCheckResult checkPermission(PermissionCheckRequest request);
}
