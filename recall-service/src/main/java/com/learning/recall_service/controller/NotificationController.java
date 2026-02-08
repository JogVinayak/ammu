package com.learning.recall_service.controller;

import com.learning.recall_service.dto.CreateNotificationRequest;
import com.learning.recall_service.dto.NotificationDto;
import com.learning.recall_service.service.NotificationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationService notificationService;

    /**
     * Create notifications for multiple users (internal service call)
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createNotifications(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @Valid @RequestBody CreateNotificationRequest request) {
        int created = notificationService.createNotifications(tenantId, request);
        return ResponseEntity.ok(Map.of("created", created));
    }

    /**
     * Get paginated notifications for the current user
     */
    @GetMapping
    public ResponseEntity<Page<NotificationDto>> getNotifications(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<NotificationDto> notifications = notificationService.getNotifications(tenantId, userId, page, size);
        return ResponseEntity.ok(notifications);
    }

    /**
     * Get all unread notifications for the current user
     */
    @GetMapping("/unread")
    public ResponseEntity<Map<String, Object>> getUnreadNotifications(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-User-Id") UUID userId) {
        List<NotificationDto> notifications = notificationService.getUnreadNotifications(tenantId, userId);
        long count = notificationService.getUnreadCount(tenantId, userId);
        return ResponseEntity.ok(Map.of("items", notifications, "count", count));
    }

    /**
     * Get unread notification count
     */
    @GetMapping("/unread/count")
    public ResponseEntity<Map<String, Long>> getUnreadCount(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-User-Id") UUID userId) {
        long count = notificationService.getUnreadCount(tenantId, userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * Mark a specific notification as read
     */
    @PostMapping("/{notificationId}/read")
    public ResponseEntity<Map<String, Boolean>> markAsRead(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID notificationId) {
        boolean success = notificationService.markAsRead(tenantId, userId, notificationId);
        return ResponseEntity.ok(Map.of("success", success));
    }

    /**
     * Mark all notifications as read
     */
    @PostMapping("/read-all")
    public ResponseEntity<Map<String, Integer>> markAllAsRead(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-User-Id") UUID userId) {
        int updated = notificationService.markAllAsRead(tenantId, userId);
        return ResponseEntity.ok(Map.of("updated", updated));
    }
}
