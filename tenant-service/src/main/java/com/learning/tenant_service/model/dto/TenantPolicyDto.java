package com.learning.tenant_service.model.dto;

import java.util.List;
import java.util.Map;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class TenantPolicyDto {
    private Boolean allowSelfSignup;
    private Boolean requireAdminApproval;
    private List<String> allowedAuthMethods;
    private String allowedSignupDomains;
    private Integer sessionMaxDays;
    private String quietHoursStart;
    private String quietHoursEnd;
    private Map<String, Object> extra;
}
