package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.UserPreference;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserPreferenceRepository extends JpaRepository<UserPreference, UUID> {
    Optional<UserPreference> findByTenantIdAndUserId(UUID tenantId, UUID userId);
}
