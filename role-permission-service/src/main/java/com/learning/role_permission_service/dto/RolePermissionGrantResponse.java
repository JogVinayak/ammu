package com.learning.role_permission_service.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionGrantResponse {
	private Long id;
	private Long roleId;
	private String permissionCode;
	private String scopeCode;
	private String constraintsJson;
	private Instant createdAt;
	private String createdBy;
}
