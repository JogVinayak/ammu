package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.StudentProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import com.learning.user_profile_service.service.StudentProfileService;
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
@RequestMapping("/v1/tenants/{tenantId}/users/{userId}/student-profile")
public class StudentProfileController {
    private final StudentProfileService studentProfileService;

    @GetMapping
    public StudentProfileResponse getStudentProfile(@PathVariable UUID tenantId, @PathVariable UUID userId) {
        return studentProfileService.getStudentProfile(tenantId, userId);
    }

    @PutMapping
    public StudentProfileResponse upsertStudentProfile(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestBody StudentProfileRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String actorId) {
        return studentProfileService.upsertStudentProfile(tenantId, userId, request, actorId);
    }
}
