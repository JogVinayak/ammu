package com.learning.auth_service.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private long expiresIn;
    private UUID userId;
    private UUID tenantId;
    private String userType;      // STUDENT, TEACHER, ADMIN, PRINCIPAL, etc.
    private String displayName;   // User's display name
}
