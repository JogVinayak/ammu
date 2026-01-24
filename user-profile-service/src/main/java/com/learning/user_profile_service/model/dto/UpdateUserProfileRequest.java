package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.ProfileStatus;
import com.learning.user_profile_service.model.enums.UserType;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateUserProfileRequest {
    private String displayName;

    private String firstName;

    private String lastName;

    private String email;

    private String phone;

    private String avatarUrl;

    private UserType userType;

    private ProfileStatus status;
}
