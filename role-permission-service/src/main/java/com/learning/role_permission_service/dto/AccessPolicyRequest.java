package com.learning.role_permission_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccessPolicyRequest {
	private String name;
	private String effect;
	private Integer priority;
	private String resource;
	private String action;
	private String conditionJson;
	private String status;
}
