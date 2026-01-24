package com.learning.role_permission_service.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.PermissionEntity;

public interface PermissionRepository extends JpaRepository<PermissionEntity, Long> {
	Optional<PermissionEntity> findByCode(String code);

	List<PermissionEntity> findByCodeIn(Collection<String> codes);
}
