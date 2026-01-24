package com.learning.auth_service.model.dto;

import com.learning.auth_service.model.enums.AuthLevel;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class AccessTokenClaims {
    private UUID userId;
    private UUID tenantId;
    private UUID sessionId;
    private Instant issuedAt;
    private Instant expiresAt;
    private AuthLevel authLevel;
    private int version;

}
