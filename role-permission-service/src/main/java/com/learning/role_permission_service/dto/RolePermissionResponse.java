package com.learning.role_permission_service.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionResponse {
	private Long id;
	private Long roleId;
	private Long permissionId;
	private Instant createdAt;
	private Instant updatedAt;
}
