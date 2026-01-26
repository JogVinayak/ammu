package com.learning.role_permission_service.dto;

import java.time.Instant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccessPolicyResponse {
	private Long id;
	private String tenantId;
	private String name;
	private String effect;
	private Integer priority;
	private String resource;
	private String action;
	private String conditionJson;
	private String status;
	private Instant createdAt;
	private String createdBy;
}
