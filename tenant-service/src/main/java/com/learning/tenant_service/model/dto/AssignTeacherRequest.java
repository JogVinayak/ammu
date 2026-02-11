package com.learning.tenant_service.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class AssignTeacherRequest {
    @NotNull(message = "Teacher ID is required")
    private UUID teacherId;

    @NotBlank(message = "Role is required")
    private String role;

    private String subject;
}
