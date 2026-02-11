package com.learning.user_profile_service.service;

import com.learning.user_profile_service.exception.ResourceNotFoundException;
import com.learning.user_profile_service.model.dto.CreateUserProfileRequest;
import com.learning.user_profile_service.model.dto.UpdateUserProfileRequest;
import com.learning.user_profile_service.model.dto.UserProfileResponse;
import com.learning.user_profile_service.model.entity.UserProfile;
import com.learning.user_profile_service.model.enums.ProfileStatus;
import com.learning.user_profile_service.repository.StudentProfileRepository;
import com.learning.user_profile_service.repository.UserProfileRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultUserProfileService implements UserProfileService {
    private final UserProfileRepository profileRepository;
    private final StudentProfileRepository studentProfileRepository;

    public DefaultUserProfileService(UserProfileRepository profileRepository,
            StudentProfileRepository studentProfileRepository) {
        this.profileRepository = profileRepository;
        this.studentProfileRepository = studentProfileRepository;
    }

    @Override
    @Transactional
    public UserProfileResponse createProfile(UUID tenantId, CreateUserProfileRequest request, String actorId) {
        if (profileRepository.existsByTenantIdAndUserId(tenantId, request.getUserId())) {
            throw new IllegalStateException("Profile already exists for user");
        }

        Instant now = Instant.now();
        UserProfile profile = new UserProfile();
        profile.setId(UUID.randomUUID());
        profile.setTenantId(tenantId);
        profile.setUserId(request.getUserId());
        profile.setDisplayName(request.getDisplayName());
        profile.setFirstName(request.getFirstName());
        profile.setLastName(request.getLastName());
        profile.setEmail(request.getEmail());
        profile.setPhone(request.getPhone());
        profile.setAvatarUrl(request.getAvatarUrl());
        profile.setUserType(request.getUserType());
        profile.setStatus(request.getStatus() != null ? request.getStatus() : ProfileStatus.ACTIVE);
        profile.setCreatedAt(now);
        profile.setCreatedBy(actorId);
        profile.setUpdatedAt(now);
        profile.setUpdatedBy(actorId);
        return toResponse(profileRepository.save(profile));
    }

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID tenantId, UUID profileId) {
        return toResponse(getProfileEntity(tenantId, profileId));
    }

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getProfileByUserId(UUID tenantId, UUID userId) {
        UserProfile profile = profileRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found"));
        return toResponse(profile);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserProfileResponse> listProfiles(UUID tenantId) {
        return profileRepository.findByTenantId(tenantId).stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional
    public UserProfileResponse updateProfile(UUID tenantId, UUID profileId, UpdateUserProfileRequest request,
            String actorId) {
        UserProfile profile = getProfileEntity(tenantId, profileId);
        if (request.getDisplayName() != null) {
            profile.setDisplayName(request.getDisplayName());
        }
        if (request.getFirstName() != null) {
            profile.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            profile.setLastName(request.getLastName());
        }
        if (request.getEmail() != null) {
            profile.setEmail(request.getEmail());
        }
        if (request.getPhone() != null) {
            profile.setPhone(request.getPhone());
        }
        if (request.getAvatarUrl() != null) {
            profile.setAvatarUrl(request.getAvatarUrl());
        }
        if (request.getUserType() != null) {
            profile.setUserType(request.getUserType());
        }
        if (request.getStatus() != null) {
            profile.setStatus(request.getStatus());
        }
        profile.setUpdatedAt(Instant.now());
        profile.setUpdatedBy(actorId);
        return toResponse(profileRepository.save(profile));
    }

    @Override
    @Transactional
    public void deleteProfile(UUID tenantId, UUID profileId) {
        UserProfile profile = getProfileEntity(tenantId, profileId);
        // Also clean up any associated student profile
        studentProfileRepository.findByTenantIdAndUserId(tenantId, profile.getUserId())
                .ifPresent(studentProfileRepository::delete);
        profileRepository.delete(profile);
    }

    private UserProfile getProfileEntity(UUID tenantId, UUID profileId) {
        UserProfile profile = profileRepository.findById(profileId)
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found"));
        if (!profile.getTenantId().equals(tenantId)) {
            throw new ResourceNotFoundException("User profile not found");
        }
        return profile;
    }

    private UserProfileResponse toResponse(UserProfile profile) {
        UserProfileResponse response = new UserProfileResponse();
        response.setId(profile.getId());
        response.setTenantId(profile.getTenantId());
        response.setUserId(profile.getUserId());
        response.setDisplayName(profile.getDisplayName());
        response.setFirstName(profile.getFirstName());
        response.setLastName(profile.getLastName());
        response.setEmail(profile.getEmail());
        response.setPhone(profile.getPhone());
        response.setAvatarUrl(profile.getAvatarUrl());
        response.setUserType(profile.getUserType());
        response.setStatus(profile.getStatus());
        response.setCreatedAt(profile.getCreatedAt());
        response.setUpdatedAt(profile.getUpdatedAt());
        return response;
    }
}
