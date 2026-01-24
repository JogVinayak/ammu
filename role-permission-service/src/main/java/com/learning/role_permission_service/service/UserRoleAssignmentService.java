package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;

public interface UserRoleAssignmentService {
	UserRoleAssignmentEntity assignRole(Long tenantId, UserRoleAssignmentEntity assignment, String assignedBy);

	List<UserRoleAssignmentEntity> getAssignments(Long tenantId, Long userId);

	UserRoleAssignmentEntity revokeAssignment(Long tenantId, Long assignmentId);
}
