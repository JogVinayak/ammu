package com.learning.recall_service.service;

import com.learning.recall_service.entity.Notification;
import com.learning.recall_service.entity.Notification.NotificationType;
import com.learning.recall_service.repository.NotificationRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Test notification scheduler - sends test notifications every minute.
 * Enable/disable via application.properties: test.notifications.enabled=true/false
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TestNotificationScheduler {

    private final NotificationRepository notificationRepository;

    @Value("${test.notifications.enabled:false}")
    private boolean enabled;

    @Value("${test.notifications.tenant-id:tenant-greenwood}")
    private String testTenantId;

    // Test user IDs - add your test student UUIDs here
    @Value("${test.notifications.user-ids:a2000001-0001-0001-0001-000000000001,a2000001-0001-0001-0001-000000000002}")
    private List<String> testUserIds;

    private int notificationCount = 0;

    private static final String[] TEST_TITLES = {
        "New note available!",
        "Don't forget to study",
        "Your teacher posted new content",
        "Time for a quick review",
        "Check out the latest material"
    };

    private static final String[] TEST_MESSAGES = {
        "A new learning resource has been shared with your class.",
        "Keep up the great work! There's new content waiting for you.",
        "Your teacher just released some exciting new material.",
        "Stay on top of your studies with the latest notes.",
        "Fresh content is available - take a look when you have a moment!"
    };

    @Scheduled(fixedRateString = "${test.notifications.interval-ms:60000}")
    public void sendTestNotification() {
        if (!enabled) {
            return;
        }

        notificationCount++;
        int titleIndex = notificationCount % TEST_TITLES.length;
        int messageIndex = notificationCount % TEST_MESSAGES.length;

        for (String userIdStr : testUserIds) {
            try {
                UUID userId = UUID.fromString(userIdStr.trim());

                Notification notification = new Notification();
                notification.setId(UUID.randomUUID());
                notification.setTenantId(testTenantId);
                notification.setUserId(userId);
                notification.setType(NotificationType.CONTENT_RELEASED);
                notification.setTitle(TEST_TITLES[titleIndex]);
                notification.setMessage(TEST_MESSAGES[messageIndex] + " (Test #" + notificationCount + ")");
                notification.setRead(false);

                notificationRepository.save(notification);
                log.info("Sent test notification #{} to user {} in tenant {}",
                    notificationCount, userId, testTenantId);

            } catch (IllegalArgumentException e) {
                log.warn("Invalid test user ID: {}", userIdStr);
            }
        }
    }
}
