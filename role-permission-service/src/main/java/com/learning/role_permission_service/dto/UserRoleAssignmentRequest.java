package com.learning.role_permission_service.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserRoleAssignmentRequest {
	private Long roleId;
	private String scopeType;
	private String scopeId;
	private String status;
	private Instant validFrom;
	private Instant validTo;
}
