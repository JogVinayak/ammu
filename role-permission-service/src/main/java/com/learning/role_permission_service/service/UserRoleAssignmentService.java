package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;

public interface UserRoleAssignmentService {
	UserRoleAssignmentEntity assignRole(String tenantId, UserRoleAssignmentEntity assignment, String assignedBy);

	List<UserRoleAssignmentEntity> getAssignments(String tenantId, String userId);

	UserRoleAssignmentEntity revokeAssignment(String tenantId, Long assignmentId);
}
