package com.learning.user_profile_service.model.dto;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UserPreferenceResponse {
    private UUID id;
    private UUID tenantId;
    private UUID userId;
    private String language;
    private String timezone;
    private boolean notificationsEnabled;
    private Map<String, Boolean> channels;
    private Map<String, Object> extra;
    private Instant createdAt;
    private Instant updatedAt;
}
