package com.learning.role_permission_service.model;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Role {
	private Long id;
	private Long tenantId;
	private String name;
	private String description;
	private Boolean isSystem;
	private String status;
	private Instant createdAt;
	private String createdBy;
	private Instant updatedAt;
	private String updatedBy;
}
