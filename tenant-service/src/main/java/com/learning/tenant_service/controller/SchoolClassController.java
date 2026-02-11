package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.AssignTeacherRequest;
import com.learning.tenant_service.model.dto.ClassResponse;
import com.learning.tenant_service.model.dto.CreateClassRequest;
import com.learning.tenant_service.model.dto.CreateDivisionRequest;
import com.learning.tenant_service.model.dto.DivisionResponse;
import com.learning.tenant_service.model.dto.TeacherAssignmentResponse;
import com.learning.tenant_service.model.dto.UpdateClassRequest;
import com.learning.tenant_service.model.dto.UpdateDivisionRequest;
import com.learning.tenant_service.service.SchoolClassService;
import com.learning.tenant_service.service.TeacherAssignmentService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/tenants/{tenantId}/classes")
public class SchoolClassController {

    private final SchoolClassService schoolClassService;
    private final TeacherAssignmentService teacherAssignmentService;

    public SchoolClassController(SchoolClassService schoolClassService,
                                  TeacherAssignmentService teacherAssignmentService) {
        this.schoolClassService = schoolClassService;
        this.teacherAssignmentService = teacherAssignmentService;
    }

    @PostMapping
    public ClassResponse createClass(
            @PathVariable UUID tenantId,
            @Valid @RequestBody CreateClassRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return schoolClassService.createClass(tenantId, request, userId);
    }

    @GetMapping
    public List<ClassResponse> listClasses(@PathVariable UUID tenantId) {
        return schoolClassService.listClasses(tenantId);
    }

    @GetMapping("/{classId}")
    public ClassResponse getClass(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId) {
        return schoolClassService.getClass(tenantId, classId);
    }

    @PutMapping("/{classId}")
    public ClassResponse updateClass(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @RequestBody UpdateClassRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return schoolClassService.updateClass(tenantId, classId, request, userId);
    }

    @DeleteMapping("/{classId}")
    public void deleteClass(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        schoolClassService.deleteClass(tenantId, classId, userId);
    }

    @PostMapping("/{classId}/divisions")
    public DivisionResponse createDivision(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @Valid @RequestBody CreateDivisionRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return schoolClassService.createDivision(tenantId, classId, request, userId);
    }

    @GetMapping("/{classId}/divisions")
    public List<DivisionResponse> listDivisions(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId) {
        return schoolClassService.listDivisions(tenantId, classId);
    }

    @PutMapping("/{classId}/divisions/{divisionId}")
    public DivisionResponse updateDivision(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @PathVariable UUID divisionId,
            @RequestBody UpdateDivisionRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return schoolClassService.updateDivision(tenantId, classId, divisionId, request, userId);
    }

    @DeleteMapping("/{classId}/divisions/{divisionId}")
    public void deleteDivision(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @PathVariable UUID divisionId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        schoolClassService.deleteDivision(tenantId, classId, divisionId, userId);
    }

    // ============== Teacher Assignments ==============

    @PostMapping("/{classId}/teachers")
    public TeacherAssignmentResponse assignTeacher(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @Valid @RequestBody AssignTeacherRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return teacherAssignmentService.assignTeacher(tenantId, classId, request, userId);
    }

    @GetMapping("/{classId}/teachers")
    public List<TeacherAssignmentResponse> listTeachers(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId) {
        return teacherAssignmentService.getTeachersForClass(tenantId, classId);
    }

    @DeleteMapping("/{classId}/teachers/{assignmentId}")
    public void removeTeacher(
            @PathVariable UUID tenantId,
            @PathVariable UUID classId,
            @PathVariable UUID assignmentId) {
        teacherAssignmentService.removeTeacher(tenantId, assignmentId);
    }
}
