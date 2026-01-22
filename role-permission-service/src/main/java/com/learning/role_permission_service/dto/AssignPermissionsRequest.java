package com.learning.role_permission_service.dto;

import java.util.Set;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignPermissionsRequest {
	private Long roleId;
	private Set<Long> permissionIds;
}
