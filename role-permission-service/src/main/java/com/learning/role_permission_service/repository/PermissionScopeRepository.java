package com.learning.role_permission_service.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.PermissionScopeEntity;

public interface PermissionScopeRepository extends JpaRepository<PermissionScopeEntity, Long> {
	Optional<PermissionScopeEntity> findByCode(String code);
}
