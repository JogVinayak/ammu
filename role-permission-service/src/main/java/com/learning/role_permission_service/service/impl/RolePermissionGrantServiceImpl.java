package com.learning.role_permission_service.service.impl;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.dto.AssignPermissionsRequest;
import com.learning.role_permission_service.entity.PermissionEntity;
import com.learning.role_permission_service.entity.RolePermissionGrantEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.PermissionRepository;
import com.learning.role_permission_service.repository.RolePermissionGrantRepository;
import com.learning.role_permission_service.repository.RoleRepository;
import com.learning.role_permission_service.service.RolePermissionGrantService;

@Service
public class RolePermissionGrantServiceImpl implements RolePermissionGrantService {
	private final RolePermissionGrantRepository grantRepository;
	private final RoleRepository roleRepository;
	private final PermissionRepository permissionRepository;

	public RolePermissionGrantServiceImpl(
			RolePermissionGrantRepository grantRepository,
			RoleRepository roleRepository,
			PermissionRepository permissionRepository) {
		this.grantRepository = grantRepository;
		this.roleRepository = roleRepository;
		this.permissionRepository = permissionRepository;
	}

	@Override
	@Transactional
	public RolePermissionGrantEntity createGrant(String tenantId, RolePermissionGrantEntity grant, String createdBy) {
		roleRepository.findByIdAndTenantId(grant.getRoleId(), tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Role not found"));

		RolePermissionGrantEntity entity = new RolePermissionGrantEntity();
		entity.setTenantId(tenantId);
		entity.setRoleId(grant.getRoleId());
		entity.setPermissionCode(grant.getPermissionCode());
		entity.setScopeCode(grant.getScopeCode());
		entity.setConstraintsJson(grant.getConstraintsJson());
		entity.setCreatedAt(Instant.now());
		entity.setCreatedBy(createdBy);
		return grantRepository.save(entity);
	}

	@Override
	@Transactional
	public List<RolePermissionGrantEntity> assignPermissions(String tenantId, AssignPermissionsRequest request, String createdBy) {
		roleRepository.findByIdAndTenantId(request.getRoleId(), tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Role not found"));

		Set<Long> permissionIds = request.getPermissionIds() == null
				? Set.of()
				: new HashSet<>(request.getPermissionIds());
		List<PermissionEntity> permissions = permissionRepository.findAllById(permissionIds);
		if (permissions.size() != permissionIds.size()) {
			throw new ResourceNotFoundException("One or more permissions not found");
		}

		Instant now = Instant.now();
		List<RolePermissionGrantEntity> grants = new ArrayList<>();
		for (PermissionEntity permission : permissions) {
			RolePermissionGrantEntity grant = new RolePermissionGrantEntity();
			grant.setTenantId(tenantId);
			grant.setRoleId(request.getRoleId());
			grant.setPermissionCode(permission.getCode());
			grant.setCreatedAt(now);
			grant.setCreatedBy(createdBy);
			grants.add(grant);
		}
		return grantRepository.saveAll(grants);
	}

	@Override
	@Transactional(readOnly = true)
	public List<RolePermissionGrantEntity> getGrants(String tenantId, Long roleId) {
		return grantRepository.findByTenantIdAndRoleId(tenantId, roleId);
	}

	@Override
	@Transactional
	public void deleteGrant(String tenantId, Long grantId) {
		RolePermissionGrantEntity existing = grantRepository.findByIdAndTenantId(grantId, tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Grant not found"));
		grantRepository.delete(existing);
	}
}
