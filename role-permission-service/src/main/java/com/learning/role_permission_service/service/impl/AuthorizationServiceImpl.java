package com.learning.role_permission_service.service.impl;

import java.lang.reflect.Array;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.dto.PermissionCheckRequest;
import com.learning.role_permission_service.dto.PermissionCheckResult;
import com.learning.role_permission_service.entity.RolePermissionGrantEntity;
import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;
import com.learning.role_permission_service.repository.RolePermissionGrantRepository;
import com.learning.role_permission_service.repository.UserRoleAssignmentRepository;
import com.learning.role_permission_service.service.AuthorizationService;

@Service
public class AuthorizationServiceImpl implements AuthorizationService {
	private final UserRoleAssignmentRepository assignmentRepository;
	private final RolePermissionGrantRepository grantRepository;

	public AuthorizationServiceImpl(
			UserRoleAssignmentRepository assignmentRepository,
			RolePermissionGrantRepository grantRepository) {
		this.assignmentRepository = assignmentRepository;
		this.grantRepository = grantRepository;
	}

	@Override
	@Transactional(readOnly = true)
	public PermissionCheckResult checkPermission(PermissionCheckRequest request) {
		if (request == null
				|| request.getTenantId() == null
				|| request.getUserId() == null
				|| request.getResource() == null
				|| request.getAction() == null) {
			return deny("INVALID_REQUEST");
		}

		Instant now = Instant.now();
		List<UserRoleAssignmentEntity> assignments = assignmentRepository
				.findByTenantIdAndUserId(request.getTenantId(), request.getUserId());
			
		List<UserRoleAssignmentEntity> activeAssignments = new ArrayList<>();
		for (UserRoleAssignmentEntity assignment : assignments) {
			if (isActiveAssignment(assignment, now)) {
				activeAssignments.add(assignment);
			}
		}

		if (activeAssignments.isEmpty()) {
			return deny("NO_ACTIVE_ROLE_ASSIGNMENTS");
		}

		String permissionCode = buildPermissionCode(request.getResource(), request.getAction());
		List<Long> roleIds = new ArrayList<>();
		for (UserRoleAssignmentEntity assignment : activeAssignments) {
			roleIds.add(assignment.getRoleId());
		}

		List<RolePermissionGrantEntity> grants = grantRepository
				.findByTenantIdAndRoleIdInAndPermissionCode(
						request.getTenantId(),
						roleIds,
						permissionCode);
		if (grants.isEmpty()) {
			return deny("NO_MATCHING_GRANT");
		}

		Map<String, Object> context = request.getContext();
		Set<String> matchedGrants = new LinkedHashSet<>();
		Set<String> appliedScopes = new LinkedHashSet<>();
		for (RolePermissionGrantEntity grant : grants) {
			if (isScopeSatisfied(grant.getScopeCode(), activeAssignments, context, request.getUserId())) {
				if (grant.getPermissionCode() != null) {
					matchedGrants.add(grant.getPermissionCode());
				}
				if (grant.getScopeCode() != null) {
					appliedScopes.add(grant.getScopeCode());
				}
			}
		}

		if (matchedGrants.isEmpty()) {
			return deny("SCOPE_DENIED");
		}

		return new PermissionCheckResult(
				true,
				new ArrayList<>(matchedGrants),
				new ArrayList<>(appliedScopes),
				null,
				null);
	}

	private boolean isActiveAssignment(UserRoleAssignmentEntity assignment, Instant now) {
		if (assignment.getStatus() != null && !"ACTIVE".equalsIgnoreCase(assignment.getStatus())) {
			return false;
		}
		if (assignment.getValidFrom() != null && now.isBefore(assignment.getValidFrom())) {
			return false;
		}
		if (assignment.getValidTo() != null && now.isAfter(assignment.getValidTo())) {
			return false;
		}
		return true;
	}

	private String buildPermissionCode(String resource, String action) {
		return resource + ":" + action;
	}

	private boolean isScopeSatisfied(
			String scopeCode,
			List<UserRoleAssignmentEntity> assignments,
			Map<String, Object> context,
			String userId) {
		if (scopeCode == null || scopeCode.isBlank()) {
			return true;
		}

		String normalized = scopeCode.trim().toUpperCase();
		switch (normalized) {
			case "TENANT":
				return true;
			case "OWN":
				return matchesOwner(context, userId);
			case "ASSIGNED":
				return matchesAssigned(context, userId);
			case "PUBLISHED_ONLY":
				return isPublished(context);
			default:
				return matchesScopedAssignment(normalized, assignments, context);
		}
	}

	private boolean matchesOwner(Map<String, Object> context, String userId) {
		if (context == null) {
			return false;
		}
		return matchesUserId(context.get("ownerId"), userId);
	}

	private boolean matchesAssigned(Map<String, Object> context, String userId) {
		if (context == null) {
			return false;
		}
		Object value = context.get("assignedUserIds");
		if (value == null) {
			value = context.get("mentorIds");
		}
		if (value == null) {
			value = context.get("assignedUserId");
		}
		return matchesUserId(value, userId);
	}

	private boolean matchesScopedAssignment(
			String scopeCode,
			List<UserRoleAssignmentEntity> assignments,
			Map<String, Object> context) {
		String scopeId = resolveScopeId(scopeCode, context);
		if (scopeId == null || scopeId.isBlank()) {
			return false;
		}

		for (UserRoleAssignmentEntity assignment : assignments) {
			String assignmentScopeId = assignment.getScopeId();
			if (assignment.getScopeType() != null
					&& assignmentScopeId != null
					&& scopeCode.equalsIgnoreCase(assignment.getScopeType())
					&& scopeId.equalsIgnoreCase(assignmentScopeId)) {
				return true;
			}
		}
		return false;
	}

	private String resolveScopeId(String scopeCode, Map<String, Object> context) {
		if (context == null) {
			return null;
		}
		Object value = context.get("scopeId");
		if (value == null) {
			String key = scopeCode.toLowerCase() + "Id";
			value = context.get(key);
		}
		return value == null ? null : String.valueOf(value);
	}

	private boolean isPublished(Map<String, Object> context) {
		if (context == null) {
			return false;
		}
		Object status = context.get("contentStatus");
		return status != null && "PUBLISHED".equalsIgnoreCase(String.valueOf(status));
	}

	private boolean matchesUserId(Object value, String userId) {
		if (value == null || userId == null || userId.isBlank()) {
			return false;
		}
		if (value instanceof Iterable) {
			for (Object item : (Iterable<?>) value) {
				if (matchesUserId(item, userId)) {
					return true;
				}
			}
			return false;
		}
		if (value.getClass().isArray()) {
			int length = Array.getLength(value);
			for (int index = 0; index < length; index += 1) {
				Object item = Array.get(value, index);
				if (matchesUserId(item, userId)) {
					return true;
				}
			}
			return false;
		}
		String text = String.valueOf(value).trim();
		if (text.equalsIgnoreCase(userId)) {
			return true;
		}
		if (text.contains(",")) {
			String[] parts = text.split(",");
			for (String part : parts) {
				if (part.trim().equalsIgnoreCase(userId)) {
					return true;
				}
			}
		}
		return false;
	}

	private PermissionCheckResult deny(String reason) {
		return new PermissionCheckResult(false, List.of(), List.of(), reason, null);
	}
}
