package com.learning.role_permission_service.model;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserRoleAssignment {
	private Long id;
	private Long tenantId;
	private Long userId;
	private Long roleId;
	private String scopeType;
	private String scopeId;
	private String status;
	private Instant validFrom;
	private Instant validTo;
	private String assignedBy;
	private Instant createdAt;
}
