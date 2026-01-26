package com.learning.role_permission_service.model;

import java.time.Instant;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionGrant {
	private Long id;
	private String tenantId;
	private Long roleId;
	private String permissionCode;
	private String scopeCode;
	private List<PermissionConstraint> constraints;
	private Instant createdAt;
	private String createdBy;
}
