package com.learning.role_permission_service.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.PermissionCheckRequest;
import com.learning.role_permission_service.dto.PermissionCheckResult;
import com.learning.role_permission_service.service.AuthorizationService;

@RestController
@RequestMapping("/authorize")
public class AuthorizationController {
	private final AuthorizationService authorizationService;

	public AuthorizationController(AuthorizationService authorizationService) {
		this.authorizationService = authorizationService;
	}

	@PostMapping("/check")
	public PermissionCheckResult check(@RequestBody PermissionCheckRequest request) {
		return authorizationService.checkPermission(request);
	}
}
