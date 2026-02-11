package com.learning.tenant_service.service;

import com.learning.tenant_service.model.dto.ClassResponse;
import com.learning.tenant_service.model.dto.CreateClassRequest;
import com.learning.tenant_service.model.dto.CreateDivisionRequest;
import com.learning.tenant_service.model.dto.DivisionResponse;
import com.learning.tenant_service.model.dto.UpdateClassRequest;
import com.learning.tenant_service.model.dto.UpdateDivisionRequest;
import java.util.List;
import java.util.UUID;

public interface SchoolClassService {
    ClassResponse createClass(UUID tenantId, CreateClassRequest request, String createdBy);

    List<ClassResponse> listClasses(UUID tenantId);

    ClassResponse getClass(UUID tenantId, UUID classId);

    ClassResponse updateClass(UUID tenantId, UUID classId, UpdateClassRequest request, String updatedBy);

    void deleteClass(UUID tenantId, UUID classId, String updatedBy);

    DivisionResponse createDivision(UUID tenantId, UUID classId, CreateDivisionRequest request, String createdBy);

    List<DivisionResponse> listDivisions(UUID tenantId, UUID classId);

    DivisionResponse updateDivision(UUID tenantId, UUID classId, UUID divisionId, UpdateDivisionRequest request, String updatedBy);

    void deleteDivision(UUID tenantId, UUID classId, UUID divisionId, String updatedBy);
}
