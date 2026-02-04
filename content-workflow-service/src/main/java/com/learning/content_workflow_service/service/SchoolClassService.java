package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.dto.ClassListResponse;
import com.learning.content_workflow_service.dto.ClassResponse;
import com.learning.content_workflow_service.dto.CreateClassRequest;
import com.learning.content_workflow_service.dto.UpdateClassRequest;
import java.util.UUID;

public interface SchoolClassService {
    ClassResponse createClass(String tenantId, String userId, CreateClassRequest request);

    ClassResponse getClass(String tenantId, UUID classId);

    ClassListResponse listClasses(String tenantId, String teacherId, String grade, String subject, int page, int size);

    ClassResponse updateClass(String tenantId, UUID classId, String userId, UpdateClassRequest request);

    void deleteClass(String tenantId, UUID classId);
}
