package com.learning.role_permission_service.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.CreateRoleRequest;
import com.learning.role_permission_service.dto.RoleResponse;
import com.learning.role_permission_service.dto.UpdateRoleRequest;
import com.learning.role_permission_service.entity.RoleEntity;
import com.learning.role_permission_service.service.RoleService;

@RestController
@RequestMapping("/tenants/{tenantId}/roles")
public class RoleController {
	private final RoleService roleService;

	public RoleController(RoleService roleService) {
		this.roleService = roleService;
	}

	@PostMapping
	public RoleResponse createRole(
			@PathVariable String tenantId,
			@RequestBody CreateRoleRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String userId) {
		RoleEntity role = roleService.createRole(tenantId, request, userId);
		return toResponse(role);
	}

	@PutMapping("/{roleId}")
	public RoleResponse updateRole(
			@PathVariable String tenantId,
			@PathVariable Long roleId,
			@RequestBody UpdateRoleRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String userId) {
		request.setId(roleId);
		RoleEntity role = roleService.updateRole(tenantId, roleId, request, userId);
		return toResponse(role);
	}

	@GetMapping("/{roleId}")
	public RoleResponse getRole(@PathVariable String tenantId, @PathVariable Long roleId) {
		return toResponse(roleService.getRole(tenantId, roleId));
	}

	@GetMapping
	public List<RoleResponse> getRoles(@PathVariable String tenantId) {
		return roleService.getRoles(tenantId).stream().map(this::toResponse).toList();
	}

	@DeleteMapping("/{roleId}")
	public void deleteRole(@PathVariable String tenantId, @PathVariable Long roleId) {
		roleService.deleteRole(tenantId, roleId);
	}

	private RoleResponse toResponse(RoleEntity role) {
		boolean active = role.getStatus() != null && "ACTIVE".equalsIgnoreCase(role.getStatus());
		return new RoleResponse(
				role.getId(),
				role.getName(),
				role.getDescription(),
				active,
				role.getCreatedAt(),
				role.getUpdatedAt());
	}
}
