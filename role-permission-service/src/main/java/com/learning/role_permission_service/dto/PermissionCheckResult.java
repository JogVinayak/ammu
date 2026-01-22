package com.learning.role_permission_service.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionCheckResult {
	private boolean allowed;
	private List<String> matchedGrants;
	private List<String> appliedScopes;
	private String denyReason;
	private String debugTraceId;
}
