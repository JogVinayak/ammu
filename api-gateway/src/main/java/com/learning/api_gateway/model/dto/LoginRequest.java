package com.learning.api_gateway.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class LoginRequest {
    private UUID tenantId;
    private String identifier;
    private String password;
    private String otp;

}
