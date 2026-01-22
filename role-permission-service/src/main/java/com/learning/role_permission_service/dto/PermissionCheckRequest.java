package com.learning.role_permission_service.dto;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionCheckRequest {
	private Long tenantId;
	private Long userId;
	private String resource;
	private String action;
	private String resourceId;
	private Map<String, Object> context;
}
