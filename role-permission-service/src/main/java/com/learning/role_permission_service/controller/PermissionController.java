package com.learning.role_permission_service.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.CreatePermissionRequest;
import com.learning.role_permission_service.dto.PermissionResponse;
import com.learning.role_permission_service.dto.UpdatePermissionRequest;
import com.learning.role_permission_service.entity.PermissionEntity;
import com.learning.role_permission_service.service.PermissionService;

@RestController
@RequestMapping("/permissions")
public class PermissionController {
	private final PermissionService permissionService;

	public PermissionController(PermissionService permissionService) {
		this.permissionService = permissionService;
	}

	@PostMapping
	public PermissionResponse createPermission(@RequestBody CreatePermissionRequest request) {
		return toResponse(permissionService.createPermission(request));
	}

	@PutMapping("/{permissionId}")
	public PermissionResponse updatePermission(
			@PathVariable Long permissionId,
			@RequestBody UpdatePermissionRequest request) {
		request.setId(permissionId);
		return toResponse(permissionService.updatePermission(permissionId, request));
	}

	@GetMapping("/{code}")
	public PermissionResponse getPermission(@PathVariable String code) {
		return toResponse(permissionService.getPermissionByCode(code));
	}

	@GetMapping
	public List<PermissionResponse> getPermissions() {
		return permissionService.getPermissions().stream().map(this::toResponse).toList();
	}

	private PermissionResponse toResponse(PermissionEntity permission) {
		boolean active = permission.getIsDeprecated() == null || !permission.getIsDeprecated();
		return new PermissionResponse(
				permission.getId(),
				permission.getCode(),
				permission.getDescription(),
				permission.getResource(),
				permission.getAction(),
				active,
				permission.getCreatedAt(),
				null);
	}
}
