package com.learning.role_permission_service.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PolicyCondition {
	private String subjectAttr;
	private String operator;
	private Object value;
	private String resourceAttr;
}
