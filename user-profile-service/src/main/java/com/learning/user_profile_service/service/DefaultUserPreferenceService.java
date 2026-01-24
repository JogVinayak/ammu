package com.learning.user_profile_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.user_profile_service.exception.ResourceNotFoundException;
import com.learning.user_profile_service.model.dto.UserPreferenceRequest;
import com.learning.user_profile_service.model.dto.UserPreferenceResponse;
import com.learning.user_profile_service.model.entity.UserPreference;
import com.learning.user_profile_service.repository.UserPreferenceRepository;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultUserPreferenceService implements UserPreferenceService {
    private static final boolean DEFAULT_NOTIFICATIONS_ENABLED = true;

    private final UserPreferenceRepository preferenceRepository;
    private final ObjectMapper objectMapper;

    public DefaultUserPreferenceService(UserPreferenceRepository preferenceRepository, ObjectMapper objectMapper) {
        this.preferenceRepository = preferenceRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public UserPreferenceResponse getPreferences(UUID tenantId, UUID userId) {
        UserPreference preference = preferenceRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("User preferences not found"));
        return toResponse(preference);
    }

    @Override
    @Transactional
    public UserPreferenceResponse upsertPreferences(UUID tenantId, UUID userId, UserPreferenceRequest request,
            String actorId) {
        Instant now = Instant.now();
        UserPreference preference = preferenceRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseGet(() -> {
                    UserPreference created = new UserPreference();
                    created.setId(UUID.randomUUID());
                    created.setTenantId(tenantId);
                    created.setUserId(userId);
                    created.setCreatedAt(now);
                    created.setNotificationsEnabled(DEFAULT_NOTIFICATIONS_ENABLED);
                    return created;
                });

        if (request.getLanguage() != null) {
            preference.setLanguage(request.getLanguage());
        }
        if (request.getTimezone() != null) {
            preference.setTimezone(request.getTimezone());
        }
        if (request.getNotificationsEnabled() != null) {
            preference.setNotificationsEnabled(request.getNotificationsEnabled());
        }
        if (request.getChannels() != null) {
            preference.setChannels(serializeJson(request.getChannels()));
        }
        if (request.getExtra() != null) {
            preference.setExtra(serializeJson(request.getExtra()));
        }

        preference.setUpdatedAt(now);
        return toResponse(preferenceRepository.save(preference));
    }

    private String serializeJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("Unable to serialize json", ex);
        }
    }

    private Map<String, Boolean> deserializeChannels(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Boolean>>() {});
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to deserialize channels", ex);
        }
    }

    private Map<String, Object> deserializeExtra(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to deserialize extra", ex);
        }
    }

    private UserPreferenceResponse toResponse(UserPreference preference) {
        UserPreferenceResponse response = new UserPreferenceResponse();
        response.setId(preference.getId());
        response.setTenantId(preference.getTenantId());
        response.setUserId(preference.getUserId());
        response.setLanguage(preference.getLanguage());
        response.setTimezone(preference.getTimezone());
        response.setNotificationsEnabled(preference.isNotificationsEnabled());
        response.setChannels(deserializeChannels(preference.getChannels()));
        response.setExtra(deserializeExtra(preference.getExtra()));
        response.setCreatedAt(preference.getCreatedAt());
        response.setUpdatedAt(preference.getUpdatedAt());
        return response;
    }
}
