package com.learning.content_workflow_service.client;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
@Slf4j
public class NotificationClient {
    private final RestClient restClient;

    public NotificationClient(@Qualifier("recallRestClient") RestClient restClient) {
        this.restClient = restClient;
    }

    /**
     * Send notifications to multiple users
     */
    public int sendNotifications(
            String tenantId,
            List<UUID> userIds,
            String type,
            String title,
            String message,
            UUID referenceId,
            String referenceType) {
        try {
            Map<String, Object> request = Map.of(
                    "userIds", userIds,
                    "type", type,
                    "title", title,
                    "message", message,
                    "referenceId", referenceId != null ? referenceId : "",
                    "referenceType", referenceType != null ? referenceType : "");

            Map<String, Object> response = restClient
                    .post()
                    .uri("/v1/notifications")
                    .header("X-Tenant-Id", tenantId)
                    .body(request)
                    .retrieve()
                    .body(new ParameterizedTypeReference<Map<String, Object>>() {});

            if (response != null && response.containsKey("created")) {
                int created = ((Number) response.get("created")).intValue();
                log.info("Sent {} notifications for {} users in tenant {}", created, userIds.size(), tenantId);
                return created;
            }
            return 0;
        } catch (Exception e) {
            log.warn("Failed to send notifications: {}", e.getMessage());
            return 0;
        }
    }

    /**
     * Send content release notification to students
     */
    public int sendContentReleasedNotification(
            String tenantId, List<UUID> studentIds, String contentTitle, UUID contentId, String contentType) {
        String title = "New " + contentType + " available";
        String message = "Your teacher has released \"" + contentTitle + "\" for you to study.";

        return sendNotifications(tenantId, studentIds, "CONTENT_RELEASED", title, message, contentId, contentType);
    }
}
