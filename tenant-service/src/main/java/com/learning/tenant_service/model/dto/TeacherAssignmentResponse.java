package com.learning.tenant_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignmentResponse {
    private UUID id;
    private UUID teacherId;
    private String role;
    private String subject;
    private Instant assignedAt;
}
