package com.learning.tenant_service.model.dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PolicySnapshot {
    private Boolean allowSelfSignup;
    private Boolean requireAdminApproval;
    private List<String> allowedAuthMethods;
    private Integer sessionMaxDays;
}
