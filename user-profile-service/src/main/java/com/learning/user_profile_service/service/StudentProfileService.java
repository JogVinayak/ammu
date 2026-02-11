package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ClassStudentDto;
import com.learning.user_profile_service.model.dto.StudentProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import java.util.List;
import java.util.UUID;

public interface StudentProfileService {
    StudentProfileResponse getStudentProfile(UUID tenantId, UUID userId);

    StudentProfileResponse upsertStudentProfile(UUID tenantId, UUID userId, StudentProfileRequest request,
            String actorId);

    List<ClassStudentDto> getStudentsByClassId(UUID tenantId, UUID classId);

    List<StudentProfileResponse> listStudentProfiles(UUID tenantId);
}
