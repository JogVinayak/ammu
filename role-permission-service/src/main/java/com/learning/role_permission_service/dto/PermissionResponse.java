package com.learning.role_permission_service.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PermissionResponse {
	private Long id;
	private String name;
	private String description;
	private String resource;
	private String action;
	private boolean active;
	private Instant createdAt;
	private Instant updatedAt;
}
