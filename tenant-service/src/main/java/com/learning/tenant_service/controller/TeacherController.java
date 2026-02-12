package com.learning.tenant_service.controller;

import com.learning.tenant_service.model.dto.ClassResponse;
import com.learning.tenant_service.service.TeacherAssignmentService;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/tenants/{tenantId}/teachers")
public class TeacherController {

    private final TeacherAssignmentService teacherAssignmentService;

    public TeacherController(TeacherAssignmentService teacherAssignmentService) {
        this.teacherAssignmentService = teacherAssignmentService;
    }

    @GetMapping("/{teacherId}/classes")
    public List<ClassResponse> getClassesForTeacher(
            @PathVariable UUID tenantId,
            @PathVariable UUID teacherId) {
        return teacherAssignmentService.getClassesForTeacher(tenantId, teacherId);
    }
}
