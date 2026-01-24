package com.learning.role_permission_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionGrantRequest {
	private String permissionCode;
	private String scopeCode;
	private String constraintsJson;
}
