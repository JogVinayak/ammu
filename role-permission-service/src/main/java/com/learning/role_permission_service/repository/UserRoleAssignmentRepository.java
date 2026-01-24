package com.learning.role_permission_service.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.learning.role_permission_service.entity.UserRoleAssignmentEntity;

public interface UserRoleAssignmentRepository extends JpaRepository<UserRoleAssignmentEntity, Long> {
	List<UserRoleAssignmentEntity> findByTenantIdAndUserId(Long tenantId, Long userId);

	List<UserRoleAssignmentEntity> findByTenantIdAndUserIdAndStatus(Long tenantId, Long userId, String status);

	Optional<UserRoleAssignmentEntity> findByIdAndTenantId(Long id, Long tenantId);
}
