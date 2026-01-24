package com.learning.api_gateway.model.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class OtpSendResponse {
    private UUID challengeId;
    private Instant expiresAt;

}
