package com.learning.tenant_service.service;

import com.learning.tenant_service.exception.ResourceNotFoundException;
import com.learning.tenant_service.model.dto.ClassResponse;
import com.learning.tenant_service.model.dto.CreateClassRequest;
import com.learning.tenant_service.model.dto.CreateDivisionRequest;
import com.learning.tenant_service.model.dto.DivisionResponse;
import com.learning.tenant_service.model.dto.UpdateClassRequest;
import com.learning.tenant_service.model.dto.UpdateDivisionRequest;
import com.learning.tenant_service.model.dto.TeacherAssignmentResponse;
import com.learning.tenant_service.model.entity.Division;
import com.learning.tenant_service.model.entity.SchoolClass;
import com.learning.tenant_service.model.entity.TeacherClassAssignment;
import com.learning.tenant_service.model.enums.SchoolClassStatus;
import com.learning.tenant_service.repository.DivisionRepository;
import com.learning.tenant_service.repository.SchoolClassRepository;
import com.learning.tenant_service.repository.TeacherClassAssignmentRepository;
import com.learning.tenant_service.repository.TenantRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultSchoolClassService implements SchoolClassService {

    private final SchoolClassRepository classRepository;
    private final DivisionRepository divisionRepository;
    private final TeacherClassAssignmentRepository teacherAssignmentRepository;
    private final TenantRepository tenantRepository;

    public DefaultSchoolClassService(
            SchoolClassRepository classRepository,
            DivisionRepository divisionRepository,
            TeacherClassAssignmentRepository teacherAssignmentRepository,
            TenantRepository tenantRepository) {
        this.classRepository = classRepository;
        this.divisionRepository = divisionRepository;
        this.teacherAssignmentRepository = teacherAssignmentRepository;
        this.tenantRepository = tenantRepository;
    }

    @Override
    @Transactional
    public ClassResponse createClass(UUID tenantId, CreateClassRequest request, String createdBy) {
        verifyTenantExists(tenantId);

        Instant now = Instant.now();
        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setId(UUID.randomUUID());
        schoolClass.setTenantId(tenantId);
        schoolClass.setName(request.getName());
        schoolClass.setGradeLevel(request.getGradeLevel());
        schoolClass.setDescription(request.getDescription());
        schoolClass.setStatus(SchoolClassStatus.ACTIVE);
        schoolClass.setCreatedAt(now);
        schoolClass.setCreatedBy(createdBy);
        schoolClass.setUpdatedAt(now);
        schoolClass.setUpdatedBy(createdBy);
        classRepository.save(schoolClass);

        return toClassResponse(schoolClass, List.of());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassResponse> listClasses(UUID tenantId) {
        verifyTenantExists(tenantId);
        return classRepository.findByTenantId(tenantId).stream()
                .map(sc -> {
                    List<DivisionResponse> divisions = divisionRepository.findByClassId(sc.getId())
                            .stream().map(this::toDivisionResponse).toList();
                    return toClassResponse(sc, divisions);
                })
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ClassResponse getClass(UUID tenantId, UUID classId) {
        SchoolClass schoolClass = getClassEntity(tenantId, classId);
        List<DivisionResponse> divisions = divisionRepository.findByClassId(classId)
                .stream().map(this::toDivisionResponse).toList();
        return toClassResponse(schoolClass, divisions);
    }

    @Override
    @Transactional
    public ClassResponse updateClass(UUID tenantId, UUID classId, UpdateClassRequest request, String updatedBy) {
        SchoolClass schoolClass = getClassEntity(tenantId, classId);

        if (request.getName() != null) {
            schoolClass.setName(request.getName());
        }
        if (request.getGradeLevel() != null) {
            schoolClass.setGradeLevel(request.getGradeLevel());
        }
        if (request.getDescription() != null) {
            schoolClass.setDescription(request.getDescription());
        }
        schoolClass.setUpdatedAt(Instant.now());
        schoolClass.setUpdatedBy(updatedBy);
        classRepository.save(schoolClass);

        List<DivisionResponse> divisions = divisionRepository.findByClassId(classId)
                .stream().map(this::toDivisionResponse).toList();
        return toClassResponse(schoolClass, divisions);
    }

    @Override
    @Transactional
    public void deleteClass(UUID tenantId, UUID classId, String updatedBy) {
        SchoolClass schoolClass = getClassEntity(tenantId, classId);
        schoolClass.setStatus(SchoolClassStatus.ARCHIVED);
        schoolClass.setUpdatedAt(Instant.now());
        schoolClass.setUpdatedBy(updatedBy);
        classRepository.save(schoolClass);

        // Archive all divisions under this class
        divisionRepository.findByClassId(classId).forEach(division -> {
            division.setStatus(SchoolClassStatus.ARCHIVED);
            division.setUpdatedAt(Instant.now());
            division.setUpdatedBy(updatedBy);
            divisionRepository.save(division);
        });
    }

    @Override
    @Transactional
    public DivisionResponse createDivision(UUID tenantId, UUID classId, CreateDivisionRequest request, String createdBy) {
        SchoolClass schoolClass = getClassEntity(tenantId, classId);

        if (divisionRepository.existsByClassIdAndName(classId, request.getName())) {
            throw new IllegalStateException("Division with name '" + request.getName() + "' already exists in this class");
        }

        Instant now = Instant.now();
        Division division = new Division();
        division.setId(UUID.randomUUID());
        division.setTenantId(tenantId);
        division.setClassId(classId);
        division.setName(request.getName());
        division.setDisplayName(request.getDisplayName() != null
                ? request.getDisplayName()
                : schoolClass.getName() + " " + request.getName());
        division.setStatus(SchoolClassStatus.ACTIVE);
        division.setCreatedAt(now);
        division.setCreatedBy(createdBy);
        division.setUpdatedAt(now);
        division.setUpdatedBy(createdBy);
        divisionRepository.save(division);

        return toDivisionResponse(division);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DivisionResponse> listDivisions(UUID tenantId, UUID classId) {
        getClassEntity(tenantId, classId);
        return divisionRepository.findByClassId(classId)
                .stream().map(this::toDivisionResponse).toList();
    }

    @Override
    @Transactional
    public DivisionResponse updateDivision(UUID tenantId, UUID classId, UUID divisionId,
                                           UpdateDivisionRequest request, String updatedBy) {
        getClassEntity(tenantId, classId);
        Division division = divisionRepository.findByIdAndClassId(divisionId, classId)
                .orElseThrow(() -> new ResourceNotFoundException("Division not found"));

        if (request.getName() != null) {
            division.setName(request.getName());
        }
        if (request.getDisplayName() != null) {
            division.setDisplayName(request.getDisplayName());
        }
        division.setUpdatedAt(Instant.now());
        division.setUpdatedBy(updatedBy);
        divisionRepository.save(division);

        return toDivisionResponse(division);
    }

    @Override
    @Transactional
    public void deleteDivision(UUID tenantId, UUID classId, UUID divisionId, String updatedBy) {
        getClassEntity(tenantId, classId);
        Division division = divisionRepository.findByIdAndClassId(divisionId, classId)
                .orElseThrow(() -> new ResourceNotFoundException("Division not found"));

        division.setStatus(SchoolClassStatus.ARCHIVED);
        division.setUpdatedAt(Instant.now());
        division.setUpdatedBy(updatedBy);
        divisionRepository.save(division);
    }

    private void verifyTenantExists(UUID tenantId) {
        if (!tenantRepository.existsById(tenantId)) {
            throw new ResourceNotFoundException("Tenant not found");
        }
    }

    private SchoolClass getClassEntity(UUID tenantId, UUID classId) {
        return classRepository.findByIdAndTenantId(classId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Class not found"));
    }

    private ClassResponse toClassResponse(SchoolClass schoolClass, List<DivisionResponse> divisions) {
        List<TeacherAssignmentResponse> teachers = teacherAssignmentRepository
                .findByTenantIdAndClassId(schoolClass.getTenantId(), schoolClass.getId())
                .stream()
                .map(this::toTeacherAssignmentResponse)
                .toList();
        return new ClassResponse(
                schoolClass.getId(),
                schoolClass.getTenantId(),
                schoolClass.getName(),
                schoolClass.getGradeLevel(),
                schoolClass.getDescription(),
                schoolClass.getStatus(),
                divisions,
                teachers,
                schoolClass.getCreatedAt(),
                schoolClass.getUpdatedAt());
    }

    private TeacherAssignmentResponse toTeacherAssignmentResponse(TeacherClassAssignment assignment) {
        return new TeacherAssignmentResponse(
                assignment.getId(),
                assignment.getTeacherId(),
                assignment.getRole(),
                assignment.getSubject(),
                assignment.getAssignedAt());
    }

    private DivisionResponse toDivisionResponse(Division division) {
        return new DivisionResponse(
                division.getId(),
                division.getClassId(),
                division.getName(),
                division.getDisplayName(),
                division.getStatus(),
                division.getCreatedAt(),
                division.getUpdatedAt());
    }
}
