package com.learning.user_profile_service.service;

import com.learning.user_profile_service.exception.ResourceNotFoundException;
import com.learning.user_profile_service.model.dto.StudentProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import com.learning.user_profile_service.model.entity.StudentProfile;
import com.learning.user_profile_service.repository.StudentProfileRepository;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultStudentProfileService implements StudentProfileService {
    private final StudentProfileRepository studentProfileRepository;

    public DefaultStudentProfileService(StudentProfileRepository studentProfileRepository) {
        this.studentProfileRepository = studentProfileRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public StudentProfileResponse getStudentProfile(UUID tenantId, UUID userId) {
        StudentProfile profile = studentProfileRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Student profile not found"));
        return toResponse(profile);
    }

    @Override
    @Transactional
    public StudentProfileResponse upsertStudentProfile(UUID tenantId, UUID userId, StudentProfileRequest request,
            String actorId) {
        Instant now = Instant.now();
        StudentProfile profile = studentProfileRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseGet(() -> {
                    StudentProfile created = new StudentProfile();
                    created.setId(UUID.randomUUID());
                    created.setTenantId(tenantId);
                    created.setUserId(userId);
                    created.setCreatedAt(now);
                    return created;
                });

        if (request.getGrade() != null) {
            profile.setGrade(request.getGrade());
        }
        if (request.getSection() != null) {
            profile.setSection(request.getSection());
        }
        if (request.getRollNumber() != null) {
            profile.setRollNumber(request.getRollNumber());
        }
        if (request.getClassId() != null) {
            profile.setClassId(request.getClassId());
        }
        if (request.getBoard() != null) {
            profile.setBoard(request.getBoard());
        }
        profile.setUpdatedAt(now);
        return toResponse(studentProfileRepository.save(profile));
    }

    private StudentProfileResponse toResponse(StudentProfile profile) {
        StudentProfileResponse response = new StudentProfileResponse();
        response.setId(profile.getId());
        response.setTenantId(profile.getTenantId());
        response.setUserId(profile.getUserId());
        response.setGrade(profile.getGrade());
        response.setSection(profile.getSection());
        response.setRollNumber(profile.getRollNumber());
        response.setClassId(profile.getClassId());
        response.setBoard(profile.getBoard());
        response.setCreatedAt(profile.getCreatedAt());
        response.setUpdatedAt(profile.getUpdatedAt());
        return response;
    }
}
