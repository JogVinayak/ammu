package com.learning.role_permission_service.service.impl;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.entity.PermissionScopeEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.PermissionScopeRepository;
import com.learning.role_permission_service.service.PermissionScopeService;

@Service
public class PermissionScopeServiceImpl implements PermissionScopeService {
	private final PermissionScopeRepository scopeRepository;

	public PermissionScopeServiceImpl(PermissionScopeRepository scopeRepository) {
		this.scopeRepository = scopeRepository;
	}

	@Override
	@Transactional
	public PermissionScopeEntity createScope(PermissionScopeEntity scope) {
		return scopeRepository.save(scope);
	}

	@Override
	@Transactional
	public PermissionScopeEntity updateScope(Long scopeId, PermissionScopeEntity scope) {
		PermissionScopeEntity existing = getScope(scopeId);
		existing.setCode(scope.getCode());
		existing.setDescription(scope.getDescription());
		return scopeRepository.save(existing);
	}

	@Override
	@Transactional(readOnly = true)
	public PermissionScopeEntity getScope(Long scopeId) {
		return scopeRepository.findById(scopeId)
				.orElseThrow(() -> new ResourceNotFoundException("Permission scope not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public PermissionScopeEntity getScopeByCode(String code) {
		return scopeRepository.findByCode(code)
				.orElseThrow(() -> new ResourceNotFoundException("Permission scope not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public List<PermissionScopeEntity> getScopes() {
		return scopeRepository.findAll();
	}

	@Override
	@Transactional
	public void deleteScope(Long scopeId) {
		scopeRepository.delete(getScope(scopeId));
	}
}
