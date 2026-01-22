package com.learning.role_permission_service.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionScope {
	private Long id;
	private String code;
	private String description;
}
