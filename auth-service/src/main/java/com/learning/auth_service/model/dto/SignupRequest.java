package com.learning.auth_service.model.dto;

import com.learning.auth_service.model.enums.JoinMethod;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SignupRequest {
    private UUID tenantId;
    private String email;
    private String phone;
    private String password;
    private String name;
    private JoinMethod joinMethod;

}
