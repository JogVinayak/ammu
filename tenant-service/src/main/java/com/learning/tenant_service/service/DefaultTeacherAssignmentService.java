package com.learning.tenant_service.service;

import com.learning.tenant_service.exception.ResourceConflictException;
import com.learning.tenant_service.exception.ResourceNotFoundException;
import com.learning.tenant_service.model.dto.AssignTeacherRequest;
import com.learning.tenant_service.model.dto.TeacherAssignmentResponse;
import com.learning.tenant_service.model.entity.TeacherClassAssignment;
import com.learning.tenant_service.repository.SchoolClassRepository;
import com.learning.tenant_service.repository.TeacherClassAssignmentRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultTeacherAssignmentService implements TeacherAssignmentService {

    private final TeacherClassAssignmentRepository assignmentRepository;
    private final SchoolClassRepository classRepository;

    public DefaultTeacherAssignmentService(
            TeacherClassAssignmentRepository assignmentRepository,
            SchoolClassRepository classRepository) {
        this.assignmentRepository = assignmentRepository;
        this.classRepository = classRepository;
    }

    @Override
    @Transactional
    public TeacherAssignmentResponse assignTeacher(UUID tenantId, UUID classId,
                                                    AssignTeacherRequest request, String assignedBy) {
        if (!classRepository.findByIdAndTenantId(classId, tenantId).isPresent()) {
            throw new ResourceNotFoundException("Class not found");
        }

        if (assignmentRepository.existsByTenantIdAndClassIdAndTeacherIdAndRole(
                tenantId, classId, request.getTeacherId(), request.getRole())) {
            throw new ResourceConflictException("Teacher is already assigned to this class with role " + request.getRole());
        }

        TeacherClassAssignment assignment = new TeacherClassAssignment();
        assignment.setId(UUID.randomUUID());
        assignment.setTenantId(tenantId);
        assignment.setClassId(classId);
        assignment.setTeacherId(request.getTeacherId());
        assignment.setRole(request.getRole());
        assignment.setSubject(request.getSubject());
        assignment.setAssignedAt(Instant.now());
        assignment.setAssignedBy(assignedBy);
        assignmentRepository.save(assignment);

        return toResponse(assignment);
    }

    @Override
    @Transactional(readOnly = true)
    public List<TeacherAssignmentResponse> getTeachersForClass(UUID tenantId, UUID classId) {
        return assignmentRepository.findByTenantIdAndClassId(tenantId, classId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public void removeTeacher(UUID tenantId, UUID assignmentId) {
        TeacherClassAssignment assignment = assignmentRepository.findByIdAndTenantId(assignmentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher assignment not found"));
        assignmentRepository.delete(assignment);
    }

    private TeacherAssignmentResponse toResponse(TeacherClassAssignment assignment) {
        return new TeacherAssignmentResponse(
                assignment.getId(),
                assignment.getTeacherId(),
                assignment.getRole(),
                assignment.getSubject(),
                assignment.getAssignedAt());
    }
}
