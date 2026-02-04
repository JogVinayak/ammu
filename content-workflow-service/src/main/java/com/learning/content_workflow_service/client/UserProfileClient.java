package com.learning.content_workflow_service.client;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
@Slf4j
public class UserProfileClient {
    private final RestClient restClient;

    public UserProfileClient(@Qualifier("userProfileRestClient") RestClient restClient) {
        this.restClient = restClient;
    }

    public List<StudentInfo> getStudentsByClassId(String tenantId, UUID classId) {
        try {
            Map<String, Object> response = restClient.get()
                    .uri("/v1/classes/{classId}/students", classId)
                    .header("X-Tenant-Id", tenantId)
                    .retrieve()
                    .body(new ParameterizedTypeReference<Map<String, Object>>() {});

            if (response == null || !response.containsKey("items")) {
                return Collections.emptyList();
            }

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> items = (List<Map<String, Object>>) response.get("items");
            return items.stream()
                    .map(this::mapToStudentInfo)
                    .toList();
        } catch (Exception e) {
            log.warn("Failed to fetch students for class {}: {}", classId, e.getMessage());
            return Collections.emptyList();
        }
    }

    private StudentInfo mapToStudentInfo(Map<String, Object> data) {
        return StudentInfo.builder()
                .id(data.get("id") != null ? data.get("id").toString() : null)
                .name(data.get("name") != null ? data.get("name").toString() : "Unknown")
                .email(data.get("email") != null ? data.get("email").toString() : null)
                .avatar(data.get("avatar") != null ? data.get("avatar").toString() : null)
                .build();
    }

    @Value
    @Builder
    public static class StudentInfo {
        String id;
        String name;
        String email;
        String avatar;
    }
}
