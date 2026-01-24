package com.learning.role_permission_service.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.PermissionScopeRequest;
import com.learning.role_permission_service.dto.PermissionScopeResponse;
import com.learning.role_permission_service.entity.PermissionScopeEntity;
import com.learning.role_permission_service.service.PermissionScopeService;

@RestController
@RequestMapping("/permission-scopes")
public class PermissionScopeController {
	private final PermissionScopeService scopeService;

	public PermissionScopeController(PermissionScopeService scopeService) {
		this.scopeService = scopeService;
	}

	@PostMapping
	public PermissionScopeResponse createScope(@RequestBody PermissionScopeRequest request) {
		PermissionScopeEntity scope = new PermissionScopeEntity(null, request.getCode(), request.getDescription());
		return toResponse(scopeService.createScope(scope));
	}

	@PutMapping("/{scopeId}")
	public PermissionScopeResponse updateScope(
			@PathVariable Long scopeId,
			@RequestBody PermissionScopeRequest request) {
		PermissionScopeEntity scope = new PermissionScopeEntity(scopeId, request.getCode(), request.getDescription());
		return toResponse(scopeService.updateScope(scopeId, scope));
	}

	@GetMapping("/{scopeId}")
	public PermissionScopeResponse getScope(@PathVariable Long scopeId) {
		return toResponse(scopeService.getScope(scopeId));
	}

	@GetMapping("/code/{code}")
	public PermissionScopeResponse getScopeByCode(@PathVariable String code) {
		return toResponse(scopeService.getScopeByCode(code));
	}

	@GetMapping
	public List<PermissionScopeResponse> getScopes() {
		return scopeService.getScopes().stream().map(this::toResponse).toList();
	}

	@DeleteMapping("/{scopeId}")
	public void deleteScope(@PathVariable Long scopeId) {
		scopeService.deleteScope(scopeId);
	}

	private PermissionScopeResponse toResponse(PermissionScopeEntity scope) {
		return new PermissionScopeResponse(scope.getId(), scope.getCode(), scope.getDescription());
	}
}
