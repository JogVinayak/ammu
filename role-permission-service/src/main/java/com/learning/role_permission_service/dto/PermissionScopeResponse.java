package com.learning.role_permission_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionScopeResponse {
	private Long id;
	private String code;
	private String description;
}
