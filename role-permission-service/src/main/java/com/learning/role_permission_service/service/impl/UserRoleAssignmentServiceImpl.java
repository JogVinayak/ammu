package com.learning.role_permission_service.service.impl;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.RoleRepository;
import com.learning.role_permission_service.repository.UserRoleAssignmentRepository;
import com.learning.role_permission_service.service.UserRoleAssignmentService;

@Service
public class UserRoleAssignmentServiceImpl implements UserRoleAssignmentService {
	private final UserRoleAssignmentRepository assignmentRepository;
	private final RoleRepository roleRepository;

	public UserRoleAssignmentServiceImpl(
			UserRoleAssignmentRepository assignmentRepository,
			RoleRepository roleRepository) {
		this.assignmentRepository = assignmentRepository;
		this.roleRepository = roleRepository;
	}

	@Override
	@Transactional
	public UserRoleAssignmentEntity assignRole(String tenantId, UserRoleAssignmentEntity assignment, String assignedBy) {
		roleRepository.findByIdAndTenantId(assignment.getRoleId(), tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Role not found"));

		UserRoleAssignmentEntity entity = new UserRoleAssignmentEntity();
		entity.setTenantId(tenantId);
		entity.setUserId(assignment.getUserId());
		entity.setRoleId(assignment.getRoleId());
		entity.setScopeType(assignment.getScopeType());
		entity.setScopeId(assignment.getScopeId());
		entity.setStatus(assignment.getStatus() == null ? "ACTIVE" : assignment.getStatus());
		entity.setValidFrom(assignment.getValidFrom());
		entity.setValidTo(assignment.getValidTo());
		entity.setAssignedBy(assignedBy);
		entity.setCreatedAt(Instant.now());
		return assignmentRepository.save(entity);
	}

	@Override
	@Transactional(readOnly = true)
	public List<UserRoleAssignmentEntity> getAssignments(String tenantId, String userId) {
		return assignmentRepository.findByTenantIdAndUserId(tenantId, userId);
	}

	@Override
	@Transactional
	public UserRoleAssignmentEntity revokeAssignment(String tenantId, Long assignmentId) {
		UserRoleAssignmentEntity existing = assignmentRepository.findByIdAndTenantId(assignmentId, tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Assignment not found"));
		existing.setStatus("REVOKED");
		existing.setValidTo(Instant.now());
		return assignmentRepository.save(existing);
	}
}
