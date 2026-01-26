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

import com.learning.role_permission_service.dto.AssignPermissionsRequest;
import com.learning.role_permission_service.dto.RolePermissionGrantRequest;
import com.learning.role_permission_service.dto.RolePermissionGrantResponse;
import com.learning.role_permission_service.entity.RolePermissionGrantEntity;
import com.learning.role_permission_service.service.RolePermissionGrantService;

@RestController
@RequestMapping("/tenants/{tenantId}/roles/{roleId}/grants")
public class RolePermissionGrantController {
	private final RolePermissionGrantService grantService;

	public RolePermissionGrantController(RolePermissionGrantService grantService) {
		this.grantService = grantService;
	}

	@PostMapping
	public RolePermissionGrantResponse createGrant(
			@PathVariable String tenantId,
			@PathVariable Long roleId,
			@RequestBody RolePermissionGrantRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String userId) {
		RolePermissionGrantEntity grant = new RolePermissionGrantEntity();
		grant.setRoleId(roleId);
		grant.setPermissionCode(request.getPermissionCode());
		grant.setScopeCode(request.getScopeCode());
		grant.setConstraintsJson(request.getConstraintsJson());
		return toResponse(grantService.createGrant(tenantId, grant, userId));
	}

	@PostMapping("/assign")
	public List<RolePermissionGrantResponse> assignPermissions(
			@PathVariable String tenantId,
			@PathVariable Long roleId,
			@RequestBody AssignPermissionsRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String userId) {
		request.setRoleId(roleId);
		return grantService.assignPermissions(tenantId, request, userId).stream()
				.map(this::toResponse)
				.toList();
	}

	@GetMapping
	public List<RolePermissionGrantResponse> getGrants(
			@PathVariable String tenantId,
			@PathVariable Long roleId) {
		return grantService.getGrants(tenantId, roleId).stream().map(this::toResponse).toList();
	}

	@DeleteMapping("/{grantId}")
	public void deleteGrant(@PathVariable String tenantId, @PathVariable Long grantId) {
		grantService.deleteGrant(tenantId, grantId);
	}

	private RolePermissionGrantResponse toResponse(RolePermissionGrantEntity grant) {
		return new RolePermissionGrantResponse(
				grant.getId(),
				grant.getRoleId(),
				grant.getPermissionCode(),
				grant.getScopeCode(),
				grant.getConstraintsJson(),
				grant.getCreatedAt(),
				grant.getCreatedBy());
	}
}
