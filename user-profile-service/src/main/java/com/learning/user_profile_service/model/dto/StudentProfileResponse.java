package com.learning.user_profile_service.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class StudentProfileResponse {
    private UUID id;
    private UUID tenantId;
    private UUID userId;
    private String grade;
    private String section;
    private String rollNumber;
    private UUID classId;
    private UUID divisionId;
    private String board;
    private Instant createdAt;
    private Instant updatedAt;
}
