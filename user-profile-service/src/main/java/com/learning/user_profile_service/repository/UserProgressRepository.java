package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.UserProgress;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserProgressRepository extends JpaRepository<UserProgress, UUID> {
    Optional<UserProgress> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    boolean existsByTenantIdAndUserId(UUID tenantId, UUID userId);
}
