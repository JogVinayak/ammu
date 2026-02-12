package com.learning.tenant_service.service;

import com.learning.tenant_service.model.dto.AssignTeacherRequest;
import com.learning.tenant_service.model.dto.ClassResponse;
import com.learning.tenant_service.model.dto.TeacherAssignmentResponse;
import java.util.List;
import java.util.UUID;

public interface TeacherAssignmentService {
    TeacherAssignmentResponse assignTeacher(UUID tenantId, UUID classId, AssignTeacherRequest request, String assignedBy);

    List<TeacherAssignmentResponse> getTeachersForClass(UUID tenantId, UUID classId);

    void removeTeacher(UUID tenantId, UUID assignmentId);

    List<ClassResponse> getClassesForTeacher(UUID tenantId, UUID teacherId);
}
