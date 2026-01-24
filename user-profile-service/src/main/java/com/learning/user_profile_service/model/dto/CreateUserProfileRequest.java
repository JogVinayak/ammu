package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ProfileStatus;
import com.learning.user_profile_service.model.enums.UserType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CreateUserProfileRequest {
    @NotNull
    private UUID userId;

    @NotBlank
    private String displayName;

    private String firstName;

    private String lastName;

    private String email;

    private String phone;

    private String avatarUrl;

    private UserType userType;

    private ProfileStatus status;
}
