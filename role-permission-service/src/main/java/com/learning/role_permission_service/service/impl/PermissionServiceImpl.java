package com.learning.role_permission_service.service.impl;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.dto.CreatePermissionRequest;
import com.learning.role_permission_service.dto.UpdatePermissionRequest;
import com.learning.role_permission_service.entity.PermissionEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.PermissionRepository;
import com.learning.role_permission_service.service.PermissionService;

@Service
public class PermissionServiceImpl implements PermissionService {
	private final PermissionRepository permissionRepository;

	public PermissionServiceImpl(PermissionRepository permissionRepository) {
		this.permissionRepository = permissionRepository;
	}

	@Override
	@Transactional
	public PermissionEntity createPermission(CreatePermissionRequest request) {
		String code = resolveCode(request.getName(), request.getResource(), request.getAction());
		if (code == null || code.isBlank()) {
			throw new IllegalArgumentException("Permission code is required");
		}
		if (permissionRepository.findByCode(code).isPresent()) {
			throw new IllegalStateException("Permission code already exists");
		}

		PermissionEntity permission = new PermissionEntity();
		permission.setCode(code);
		permission.setResource(request.getResource());
		permission.setAction(request.getAction());
		permission.setDescription(request.getDescription());
		permission.setIsDeprecated(!request.isActive());
		permission.setCreatedAt(Instant.now());
		return permissionRepository.save(permission);
	}

	@Override
	@Transactional
	public PermissionEntity updatePermission(Long permissionId, UpdatePermissionRequest request) {
		PermissionEntity existing = getPermission(permissionId);
		String code = resolveCode(request.getName(), request.getResource(), request.getAction());
		if (code != null && !code.isBlank() && !code.equals(existing.getCode())) {
			if (permissionRepository.findByCode(code).isPresent()) {
				throw new IllegalStateException("Permission code already exists");
			}
			existing.setCode(code);
		}

		existing.setResource(request.getResource());
		existing.setAction(request.getAction());
		existing.setDescription(request.getDescription());
		existing.setIsDeprecated(!request.isActive());
		return permissionRepository.save(existing);
	}

	@Override
	@Transactional(readOnly = true)
	public PermissionEntity getPermission(Long permissionId) {
		return permissionRepository.findById(permissionId)
				.orElseThrow(() -> new ResourceNotFoundException("Permission not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public PermissionEntity getPermissionByCode(String code) {
		return permissionRepository.findByCode(code)
				.orElseThrow(() -> new ResourceNotFoundException("Permission not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public List<PermissionEntity> getPermissions() {
		return permissionRepository.findAll();
	}

	private String resolveCode(String name, String resource, String action) {
		if (name != null && !name.isBlank()) {
			return name;
		}
		if (resource != null && action != null) {
			return resource + ":" + action;
		}
		return null;
	}
}
