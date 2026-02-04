package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.UserProfile;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {
    boolean existsByTenantIdAndUserId(UUID tenantId, UUID userId);

    Optional<UserProfile> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<UserProfile> findByTenantId(UUID tenantId);

    List<UserProfile> findByTenantIdAndUserIdIn(UUID tenantId, Collection<UUID> userIds);
}
