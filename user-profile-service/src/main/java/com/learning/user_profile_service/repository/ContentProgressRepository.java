package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.ContentProgress;
import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.ProgressStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentProgressRepository extends JpaRepository<ContentProgress, UUID> {
    Optional<ContentProgress> findByTenantIdAndUserIdAndContentIdAndContentType(
            UUID tenantId, UUID userId, UUID contentId, ContentType contentType);

    List<ContentProgress> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<ContentProgress> findByTenantIdAndUserIdAndContentType(
            UUID tenantId, UUID userId, ContentType contentType);

    List<ContentProgress> findByTenantIdAndUserIdAndStatus(
            UUID tenantId, UUID userId, ProgressStatus status);

    long countByTenantIdAndUserIdAndContentTypeAndStatus(
            UUID tenantId, UUID userId, ContentType contentType, ProgressStatus status);
}
