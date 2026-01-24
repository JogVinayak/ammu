package com.learning.role_permission_service.service.impl;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.dto.CreateRoleRequest;
import com.learning.role_permission_service.dto.UpdateRoleRequest;
import com.learning.role_permission_service.entity.RoleEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.RoleRepository;
import com.learning.role_permission_service.service.RoleService;

@Service
public class RoleServiceImpl implements RoleService {
	private final RoleRepository roleRepository;

	public RoleServiceImpl(RoleRepository roleRepository) {
		this.roleRepository = roleRepository;
	}

	@Override
	@Transactional
	public RoleEntity createRole(Long tenantId, CreateRoleRequest request, String createdBy) {
		if (roleRepository.existsByTenantIdAndName(tenantId, request.getName())) {
			throw new IllegalStateException("Role name already exists for tenant");
		}

		Instant now = Instant.now();
		RoleEntity role = new RoleEntity();
		role.setTenantId(tenantId);
		role.setName(request.getName());
		role.setDescription(request.getDescription());
		role.setIsSystem(Boolean.FALSE);
		role.setStatus(toStatus(request.isActive()));
		role.setCreatedAt(now);
		role.setCreatedBy(createdBy);
		role.setUpdatedAt(now);
		role.setUpdatedBy(createdBy);
		return roleRepository.save(role);
	}

	@Override
	@Transactional
	public RoleEntity updateRole(Long tenantId, Long roleId, UpdateRoleRequest request, String updatedBy) {
		RoleEntity existing = getRole(tenantId, roleId);
		if (Boolean.TRUE.equals(existing.getIsSystem())) {
			throw new IllegalStateException("System roles cannot be modified");
		}

		existing.setName(request.getName());
		existing.setDescription(request.getDescription());
		existing.setStatus(toStatus(request.isActive()));
		existing.setUpdatedAt(Instant.now());
		existing.setUpdatedBy(updatedBy);
		return roleRepository.save(existing);
	}

	@Override
	@Transactional(readOnly = true)
	public RoleEntity getRole(Long tenantId, Long roleId) {
		return roleRepository.findByIdAndTenantId(roleId, tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Role not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public List<RoleEntity> getRoles(Long tenantId) {
		return roleRepository.findByTenantId(tenantId);
	}

	@Override
	@Transactional
	public void deleteRole(Long tenantId, Long roleId) {
		RoleEntity existing = getRole(tenantId, roleId);
		if (Boolean.TRUE.equals(existing.getIsSystem())) {
			throw new IllegalStateException("System roles cannot be deleted");
		}
		roleRepository.delete(existing);
	}

	private String toStatus(boolean active) {
		return active ? "ACTIVE" : "DISABLED";
	}
}
