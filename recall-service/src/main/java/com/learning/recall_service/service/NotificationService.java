package com.learning.recall_service.service;

import com.learning.recall_service.dto.CreateNotificationRequest;
import com.learning.recall_service.dto.NotificationDto;
import com.learning.recall_service.entity.Notification;
import com.learning.recall_service.entity.Notification.NotificationType;
import com.learning.recall_service.repository.NotificationRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    private final NotificationRepository notificationRepository;

    @Transactional
    public int createNotifications(String tenantId, CreateNotificationRequest request) {
        NotificationType type;
        try {
            type = NotificationType.valueOf(request.getType());
        } catch (IllegalArgumentException e) {
            type = NotificationType.SYSTEM_ANNOUNCEMENT;
        }

        int created = 0;
        for (UUID userId : request.getUserIds()) {
            Notification notification = new Notification();
            notification.setId(UUID.randomUUID());
            notification.setTenantId(tenantId);
            notification.setUserId(userId);
            notification.setType(type);
            notification.setTitle(request.getTitle());
            notification.setMessage(request.getMessage());
            notification.setReferenceId(request.getReferenceId());
            notification.setReferenceType(request.getReferenceType());
            notification.setRead(false);

            notificationRepository.save(notification);
            created++;

            log.info("Created notification for user {} in tenant {}: {}", userId, tenantId, request.getTitle());
        }

        return created;
    }

    @Transactional(readOnly = true)
    public Page<NotificationDto> getNotifications(String tenantId, UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        return notificationRepository
                .findByTenantIdAndUserIdOrderByCreatedAtDesc(tenantId, userId, pageable)
                .map(NotificationDto::from);
    }

    @Transactional(readOnly = true)
    public List<NotificationDto> getUnreadNotifications(String tenantId, UUID userId) {
        return notificationRepository
                .findByTenantIdAndUserIdAndReadFalseOrderByCreatedAtDesc(tenantId, userId)
                .stream()
                .map(NotificationDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(String tenantId, UUID userId) {
        return notificationRepository.countUnread(tenantId, userId);
    }

    @Transactional
    public boolean markAsRead(String tenantId, UUID userId, UUID notificationId) {
        int updated = notificationRepository.markAsRead(notificationId, tenantId, userId);
        return updated > 0;
    }

    @Transactional
    public int markAllAsRead(String tenantId, UUID userId) {
        return notificationRepository.markAllAsRead(tenantId, userId);
    }
}
