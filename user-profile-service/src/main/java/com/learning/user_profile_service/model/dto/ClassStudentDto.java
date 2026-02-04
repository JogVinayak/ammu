package com.learning.user_profile_service.model.dto;

import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ClassStudentDto {
    UUID id;
    String name;
    String email;
    String avatar;
    String grade;
    String section;
    String rollNumber;
}
