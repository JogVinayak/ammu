package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.client.UserProfileClient;
import com.learning.content_workflow_service.dto.ClassListResponse;
import com.learning.content_workflow_service.dto.ClassResponse;
import com.learning.content_workflow_service.dto.CreateClassRequest;
import com.learning.content_workflow_service.dto.UpdateClassRequest;
import com.learning.content_workflow_service.entity.SchoolClass;
import com.learning.content_workflow_service.exception.NotFoundException;
import com.learning.content_workflow_service.repository.SchoolClassRepository;
import com.learning.content_workflow_service.repository.TeacherClassAssignmentRepository;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultSchoolClassService implements SchoolClassService {
    private final SchoolClassRepository classRepository;
    private final TeacherClassAssignmentRepository teacherAssignmentRepository;
    private final UserProfileClient userProfileClient;

    @Override
    @Transactional
    public ClassResponse createClass(String tenantId, String userId, CreateClassRequest request) {
        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setId(UUID.randomUUID());
        schoolClass.setTenantId(tenantId);
        schoolClass.setName(request.getName());
        schoolClass.setSubject(request.getSubject());
        schoolClass.setGrade(request.getGrade());
        schoolClass.setDescription(request.getDescription());
        schoolClass.setStudentCount(0);
        schoolClass.setCreatedBy(userId);
        schoolClass.setCreatedAt(Instant.now());
        schoolClass.setUpdatedAt(Instant.now());

        schoolClass = classRepository.save(schoolClass);
        return toResponse(schoolClass);
    }

    @Override
    @Transactional(readOnly = true)
    public ClassResponse getClass(String tenantId, UUID classId) {
        SchoolClass schoolClass = classRepository.findByIdAndTenantId(classId, tenantId)
                .orElseThrow(() -> new NotFoundException("Class not found: " + classId));
        return toResponseWithStudents(schoolClass, tenantId);
    }

    @Override
    @Transactional(readOnly = true)
    public ClassListResponse listClasses(String tenantId, String teacherId, String grade, String subject, int page, int size) {
        // If teacherId is provided, filter by teacher assignments
        if (teacherId != null && !teacherId.isEmpty()) {
            try {
                UUID teacherUuid = UUID.fromString(teacherId);
                List<UUID> assignedClassIds = teacherAssignmentRepository.findClassIdsByTenantIdAndTeacherId(tenantId, teacherUuid);

                if (assignedClassIds.isEmpty()) {
                    return ClassListResponse.builder()
                            .items(Collections.emptyList())
                            .page(page)
                            .size(size)
                            .totalElements(0)
                            .totalPages(0)
                            .build();
                }

                List<SchoolClass> assignedClasses = classRepository.findByTenantIdAndIdIn(tenantId, assignedClassIds);
                return ClassListResponse.builder()
                        .items(assignedClasses.stream().map(this::toResponse).toList())
                        .page(page)
                        .size(size)
                        .totalElements(assignedClasses.size())
                        .totalPages(1)
                        .build();
            } catch (IllegalArgumentException e) {
                // Invalid UUID, fall through to default behavior
            }
        }

        // Default behavior: return all classes in tenant
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<SchoolClass> classPage;
        if (grade != null && !grade.isEmpty()) {
            classPage = classRepository.findByTenantIdAndGrade(tenantId, grade, pageRequest);
        } else if (subject != null && !subject.isEmpty()) {
            classPage = classRepository.findByTenantIdAndSubject(tenantId, subject, pageRequest);
        } else {
            classPage = classRepository.findByTenantId(tenantId, pageRequest);
        }

        return ClassListResponse.builder()
                .items(classPage.getContent().stream().map(this::toResponse).toList())
                .page(page)
                .size(size)
                .totalElements(classPage.getTotalElements())
                .totalPages(classPage.getTotalPages())
                .build();
    }

    @Override
    @Transactional
    public ClassResponse updateClass(String tenantId, UUID classId, String userId, UpdateClassRequest request) {
        SchoolClass schoolClass = classRepository.findByIdAndTenantId(classId, tenantId)
                .orElseThrow(() -> new NotFoundException("Class not found: " + classId));

        if (request.getName() != null) {
            schoolClass.setName(request.getName());
        }
        if (request.getSubject() != null) {
            schoolClass.setSubject(request.getSubject());
        }
        if (request.getGrade() != null) {
            schoolClass.setGrade(request.getGrade());
        }
        if (request.getDescription() != null) {
            schoolClass.setDescription(request.getDescription());
        }
        schoolClass.setUpdatedBy(userId);
        schoolClass.setUpdatedAt(Instant.now());

        schoolClass = classRepository.save(schoolClass);
        return toResponse(schoolClass);
    }

    @Override
    @Transactional
    public void deleteClass(String tenantId, UUID classId) {
        if (!classRepository.existsByIdAndTenantId(classId, tenantId)) {
            throw new NotFoundException("Class not found: " + classId);
        }
        classRepository.deleteById(classId);
    }

    private ClassResponse toResponse(SchoolClass schoolClass) {
        return ClassResponse.builder()
                .id(schoolClass.getId())
                .name(schoolClass.getName())
                .subject(schoolClass.getSubject())
                .grade(schoolClass.getGrade())
                .description(schoolClass.getDescription())
                .studentCount(schoolClass.getStudentCount() != null ? schoolClass.getStudentCount() : 0)
                .students(Collections.emptyList())
                .releasedContent(Collections.emptyList())
                .createdAt(schoolClass.getCreatedAt())
                .updatedAt(schoolClass.getUpdatedAt())
                .build();
    }

    private ClassResponse toResponseWithStudents(SchoolClass schoolClass, String tenantId) {
        List<UserProfileClient.StudentInfo> studentInfos = userProfileClient.getStudentsByClassId(tenantId, schoolClass.getId());

        List<ClassResponse.StudentDto> students = studentInfos.stream()
                .map(s -> ClassResponse.StudentDto.builder()
                        .id(s.getId())
                        .name(s.getName())
                        .email(s.getEmail())
                        .avatar(s.getAvatar())
                        .build())
                .toList();

        return ClassResponse.builder()
                .id(schoolClass.getId())
                .name(schoolClass.getName())
                .subject(schoolClass.getSubject())
                .grade(schoolClass.getGrade())
                .description(schoolClass.getDescription())
                .studentCount(students.size())
                .students(students)
                .releasedContent(Collections.emptyList())
                .createdAt(schoolClass.getCreatedAt())
                .updatedAt(schoolClass.getUpdatedAt())
                .build();
    }
}
