package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.entity.PermissionScopeEntity;

public interface PermissionScopeService {
	PermissionScopeEntity createScope(PermissionScopeEntity scope);

	PermissionScopeEntity updateScope(Long scopeId, PermissionScopeEntity scope);

	PermissionScopeEntity getScope(Long scopeId);

	PermissionScopeEntity getScopeByCode(String code);

	List<PermissionScopeEntity> getScopes();

	void deleteScope(Long scopeId);
}
