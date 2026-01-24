package com.learning.content_service.repository;

import com.learning.content_service.entity.OutboxEvent;
import com.learning.content_service.enums.OutboxStatus;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OutboxEventRepository extends JpaRepository<OutboxEvent, UUID> {
    Page<OutboxEvent> findByTenantIdAndStatus(String tenantId, OutboxStatus status, Pageable pageable);

    Optional<OutboxEvent> findByIdAndTenantId(UUID id, String tenantId);
}
