package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.StudentProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import java.util.UUID;

public interface StudentProfileService {
    StudentProfileResponse getStudentProfile(UUID tenantId, UUID userId);

    StudentProfileResponse upsertStudentProfile(UUID tenantId, UUID userId, StudentProfileRequest request,
            String actorId);
}
