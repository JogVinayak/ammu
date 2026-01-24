package com.learning.role_permission_service.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.UserRoleAssignmentRequest;
import com.learning.role_permission_service.dto.UserRoleAssignmentResponse;
import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;
import com.learning.role_permission_service.service.UserRoleAssignmentService;

@RestController
@RequestMapping("/tenants/{tenantId}/users/{userId}/roles")
public class UserRoleAssignmentController {
	private final UserRoleAssignmentService assignmentService;

	public UserRoleAssignmentController(UserRoleAssignmentService assignmentService) {
		this.assignmentService = assignmentService;
	}

	@PostMapping
	public UserRoleAssignmentResponse assignRole(
			@PathVariable Long tenantId,
			@PathVariable Long userId,
			@RequestBody UserRoleAssignmentRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String assignedBy) {
		UserRoleAssignmentEntity assignment = new UserRoleAssignmentEntity();
		assignment.setUserId(userId);
		assignment.setRoleId(request.getRoleId());
		assignment.setScopeType(request.getScopeType());
		assignment.setScopeId(request.getScopeId());
		assignment.setStatus(request.getStatus());
		assignment.setValidFrom(request.getValidFrom());
		assignment.setValidTo(request.getValidTo());
		return toResponse(assignmentService.assignRole(tenantId, assignment, assignedBy));
	}

	@GetMapping
	public List<UserRoleAssignmentResponse> getAssignments(@PathVariable Long tenantId, @PathVariable Long userId) {
		return assignmentService.getAssignments(tenantId, userId).stream().map(this::toResponse).toList();
	}

	@DeleteMapping("/{assignmentId}")
	public UserRoleAssignmentResponse revokeAssignment(
			@PathVariable Long tenantId,
			@PathVariable Long assignmentId) {
		return toResponse(assignmentService.revokeAssignment(tenantId, assignmentId));
	}

	private UserRoleAssignmentResponse toResponse(UserRoleAssignmentEntity assignment) {
		return new UserRoleAssignmentResponse(
				assignment.getId(),
				assignment.getTenantId(),
				assignment.getUserId(),
				assignment.getRoleId(),
				assignment.getScopeType(),
				assignment.getScopeId(),
				assignment.getStatus(),
				assignment.getValidFrom(),
				assignment.getValidTo(),
				assignment.getAssignedBy(),
				assignment.getCreatedAt());
	}
}
