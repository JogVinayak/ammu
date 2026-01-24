package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.UserPreferenceRequest;
import com.learning.user_profile_service.model.dto.UserPreferenceResponse;
import java.util.UUID;

public interface UserPreferenceService {
    UserPreferenceResponse getPreferences(UUID tenantId, UUID userId);

    UserPreferenceResponse upsertPreferences(UUID tenantId, UUID userId, UserPreferenceRequest request, String actorId);
}
