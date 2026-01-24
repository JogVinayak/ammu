package com.learning.api_gateway.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PasswordChangeRequest {
    private UUID userId;
    private String oldPassword;
    private String newPassword;

}
