package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.ProgressEvent;
import com.learning.user_profile_service.model.enums.ProgressEventType;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProgressEventRepository extends JpaRepository<ProgressEvent, UUID> {
    List<ProgressEvent> findByTenantIdAndUserIdOrderByCreatedAtDesc(
            UUID tenantId, UUID userId, Pageable pageable);

    List<ProgressEvent> findByTenantIdAndUserIdAndEventTypeOrderByCreatedAtDesc(
            UUID tenantId, UUID userId, ProgressEventType eventType, Pageable pageable);

    List<ProgressEvent> findByTenantIdAndUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(
            UUID tenantId, UUID userId, Instant start, Instant end);

    long countByTenantIdAndUserIdAndEventType(
            UUID tenantId, UUID userId, ProgressEventType eventType);
}
