package com.learning.recall_service.repository;

import com.learning.recall_service.entity.Notification;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    Page<Notification> findByTenantIdAndUserIdOrderByCreatedAtDesc(
            String tenantId, UUID userId, Pageable pageable);

    List<Notification> findByTenantIdAndUserIdAndReadFalseOrderByCreatedAtDesc(
            String tenantId, UUID userId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.tenantId = :tenantId AND n.userId = :userId AND n.read = false")
    long countUnread(@Param("tenantId") String tenantId, @Param("userId") UUID userId);

    @Modifying
    @Query("UPDATE Notification n SET n.read = true, n.readAt = CURRENT_TIMESTAMP, n.updatedAt = CURRENT_TIMESTAMP "
            + "WHERE n.tenantId = :tenantId AND n.userId = :userId AND n.read = false")
    int markAllAsRead(@Param("tenantId") String tenantId, @Param("userId") UUID userId);

    @Modifying
    @Query("UPDATE Notification n SET n.read = true, n.readAt = CURRENT_TIMESTAMP, n.updatedAt = CURRENT_TIMESTAMP "
            + "WHERE n.id = :id AND n.tenantId = :tenantId AND n.userId = :userId")
    int markAsRead(@Param("id") UUID id, @Param("tenantId") String tenantId, @Param("userId") UUID userId);
}
