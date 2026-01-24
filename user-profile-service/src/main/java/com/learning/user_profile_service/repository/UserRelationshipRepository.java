package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.UserRelationship;
import com.learning.user_profile_service.model.enums.RelationshipType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRelationshipRepository extends JpaRepository<UserRelationship, UUID> {
    boolean existsByTenantIdAndUserIdAndRelatedUserIdAndRelationshipType(UUID tenantId, UUID userId,
            UUID relatedUserId, RelationshipType relationshipType);

    List<UserRelationship> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    Optional<UserRelationship> findByTenantIdAndId(UUID tenantId, UUID id);
}
