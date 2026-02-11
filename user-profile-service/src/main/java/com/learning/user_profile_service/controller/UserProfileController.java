package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.CreateUserProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import com.learning.user_profile_service.model.dto.UpdateUserProfileRequest;
import com.learning.user_profile_service.model.dto.UserProfileResponse;
import com.learning.user_profile_service.service.StudentProfileService;
import com.learning.user_profile_service.service.UserProfileService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/profiles")
public class UserProfileController {
    private final UserProfileService userProfileService;
    private final StudentProfileService studentProfileService;

    @PostMapping
    public UserProfileResponse createProfile(
            @PathVariable UUID tenantId,
            @Valid @RequestBody CreateUserProfileRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String actorId) {
        return userProfileService.createProfile(tenantId, request, actorId);
    }

    @GetMapping
    public List<UserProfileResponse> listProfiles(@PathVariable UUID tenantId) {
        return userProfileService.listProfiles(tenantId);
    }

    @GetMapping("/{profileId}")
    public UserProfileResponse getProfile(@PathVariable UUID tenantId, @PathVariable UUID profileId) {
        return userProfileService.getProfile(tenantId, profileId);
    }

    @GetMapping("/by-user/{userId}")
    public UserProfileResponse getProfileByUserId(@PathVariable UUID tenantId, @PathVariable UUID userId) {
        return userProfileService.getProfileByUserId(tenantId, userId);
    }

    @GetMapping("/student-summaries")
    public List<StudentProfileResponse> listStudentProfiles(@PathVariable UUID tenantId) {
        return studentProfileService.listStudentProfiles(tenantId);
    }

    @PutMapping("/{profileId}")
    public UserProfileResponse updateProfile(
            @PathVariable UUID tenantId,
            @PathVariable UUID profileId,
            @RequestBody UpdateUserProfileRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String actorId) {
        return userProfileService.updateProfile(tenantId, profileId, request, actorId);
    }

    @DeleteMapping("/{profileId}")
    public ResponseEntity<Void> deleteProfile(@PathVariable UUID tenantId, @PathVariable UUID profileId) {
        userProfileService.deleteProfile(tenantId, profileId);
        return ResponseEntity.noContent().build();
    }
}
