package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.SchoolClassStatus;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassResponse {
    private UUID id;
    private UUID tenantId;
    private String name;
    private Integer gradeLevel;
    private String description;
    private SchoolClassStatus status;
    private List<DivisionResponse> divisions;
    private List<TeacherAssignmentResponse> teachers;
    private Instant createdAt;
    private Instant updatedAt;
}
