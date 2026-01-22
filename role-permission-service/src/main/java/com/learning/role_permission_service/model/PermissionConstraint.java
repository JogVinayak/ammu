package com.learning.role_permission_service.model;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionConstraint {
	private String type;
	private Map<String, Object> params;
}
