package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.UserPreferenceRequest;
import com.learning.user_profile_service.model.dto.UserPreferenceResponse;
import com.learning.user_profile_service.service.UserPreferenceService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/users/{userId}/preferences")
public class UserPreferenceController {
    private final UserPreferenceService preferenceService;

    @GetMapping
    public UserPreferenceResponse getPreferences(@PathVariable UUID tenantId, @PathVariable UUID userId) {
        return preferenceService.getPreferences(tenantId, userId);
    }

    @PutMapping
    public UserPreferenceResponse upsertPreferences(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestBody UserPreferenceRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String actorId) {
        return preferenceService.upsertPreferences(tenantId, userId, request, actorId);
    }
}
