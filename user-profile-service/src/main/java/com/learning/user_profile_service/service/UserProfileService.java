package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.CreateUserProfileRequest;
import com.learning.user_profile_service.model.dto.UpdateUserProfileRequest;
import com.learning.user_profile_service.model.dto.UserProfileResponse;
import java.util.List;
import java.util.UUID;

public interface UserProfileService {
    UserProfileResponse createProfile(UUID tenantId, CreateUserProfileRequest request, String actorId);

    UserProfileResponse getProfile(UUID tenantId, UUID profileId);

    UserProfileResponse getProfileByUserId(UUID tenantId, UUID userId);

    List<UserProfileResponse> listProfiles(UUID tenantId);

    UserProfileResponse updateProfile(UUID tenantId, UUID profileId, UpdateUserProfileRequest request, String actorId);
}
