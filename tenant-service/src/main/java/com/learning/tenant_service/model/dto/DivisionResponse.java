package com.learning.tenant_service.model.dto;

import com.learning.tenant_service.model.enums.SchoolClassStatus;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DivisionResponse {
    private UUID id;
    private UUID classId;
    private String name;
    private String displayName;
    private SchoolClassStatus status;
    private Instant createdAt;
    private Instant updatedAt;
}
