package com.learning.user_profile_service.service;

import com.learning.user_profile_service.exception.ResourceNotFoundException;
import com.learning.user_profile_service.model.dto.ClassStudentDto;
import com.learning.user_profile_service.model.dto.StudentProfileRequest;
import com.learning.user_profile_service.model.dto.StudentProfileResponse;
import com.learning.user_profile_service.model.entity.StudentProfile;
import com.learning.user_profile_service.model.entity.UserProfile;
import com.learning.user_profile_service.repository.StudentProfileRepository;
import com.learning.user_profile_service.repository.UserProfileRepository;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultStudentProfileService implements StudentProfileService {
    private final StudentProfileRepository studentProfileRepository;
    private final UserProfileRepository userProfileRepository;

    public DefaultStudentProfileService(StudentProfileRepository studentProfileRepository,
            UserProfileRepository userProfileRepository) {
        this.studentProfileRepository = studentProfileRepository;
        this.userProfileRepository = userProfileRepository;
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
        if (request.getDivisionId() != null) {
            profile.setDivisionId(request.getDivisionId());
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
        response.setDivisionId(profile.getDivisionId());
        response.setBoard(profile.getBoard());
        response.setCreatedAt(profile.getCreatedAt());
        response.setUpdatedAt(profile.getUpdatedAt());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<StudentProfileResponse> listStudentProfiles(UUID tenantId) {
        return studentProfileRepository.findByTenantId(tenantId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassStudentDto> getStudentsByClassId(UUID tenantId, UUID classId) {
        List<StudentProfile> studentProfiles = studentProfileRepository.findByTenantIdAndClassId(tenantId, classId);

        if (studentProfiles.isEmpty()) {
            return Collections.emptyList();
        }

        List<UUID> userIds = studentProfiles.stream()
                .map(StudentProfile::getUserId)
                .toList();

        Map<UUID, UserProfile> userProfileMap = userProfileRepository.findByTenantIdAndUserIdIn(tenantId, userIds)
                .stream()
                .collect(Collectors.toMap(UserProfile::getUserId, Function.identity()));

        return studentProfiles.stream()
                .map(sp -> {
                    UserProfile up = userProfileMap.get(sp.getUserId());
                    return ClassStudentDto.builder()
                            .id(sp.getUserId())
                            .name(up != null ? up.getDisplayName() : "Unknown")
                            .email(up != null ? up.getEmail() : null)
                            .avatar(up != null ? up.getAvatarUrl() : null)
                            .grade(sp.getGrade())
                            .section(sp.getSection())
                            .rollNumber(sp.getRollNumber())
                            .build();
                })
                .toList();
    }
}
