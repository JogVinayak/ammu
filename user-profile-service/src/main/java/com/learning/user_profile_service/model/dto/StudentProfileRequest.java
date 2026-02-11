package com.learning.user_profile_service.model.dto;

import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class StudentProfileRequest {
    private String grade;
    private String section;
    private String rollNumber;
    private UUID classId;
    private UUID divisionId;
    private String board;
}
