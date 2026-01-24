package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ProfileStatus;
import com.learning.user_profile_service.model.enums.UserType;
import java.time.Instant;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UserProfileResponse {
    private UUID id;
    private UUID tenantId;
    private UUID userId;
    private String displayName;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private String avatarUrl;
    private UserType userType;
    private ProfileStatus status;
    private Instant createdAt;
    private Instant updatedAt;
}
