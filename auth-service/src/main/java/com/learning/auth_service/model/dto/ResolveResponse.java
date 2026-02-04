package com.learning.auth_service.model.dto;

import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ResolveResponse {
    private UUID userId;
    private String displayName;
    private List<TenantInfo> tenants;

    @Getter
    @Setter
    @NoArgsConstructor
    public static class TenantInfo {
        private UUID tenantId;
        private String tenantName;
        private String userType; // STUDENT, TEACHER, ADMIN, PRINCIPAL, etc.
    }
}
