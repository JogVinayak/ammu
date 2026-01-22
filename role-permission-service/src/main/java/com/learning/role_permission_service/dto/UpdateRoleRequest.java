package com.learning.role_permission_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRoleRequest {
	private Long id;
	private String name;
	private String description;
	private boolean active;
}
