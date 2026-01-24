package com.learning.content_service.util;

import java.util.Collections;
import java.util.Set;
import java.util.UUID;
import lombok.Getter;

@Getter
public class TenantContext {
    private final String tenantId;
    private final UUID userId;
    private final String role;
    private final Set<String> permissions;

    public TenantContext(String tenantId, UUID userId, String role, Set<String> permissions) {
        this.tenantId = tenantId;
        this.userId = userId;
        this.role = role;
        this.permissions = permissions == null ? Collections.emptySet() : Collections.unmodifiableSet(permissions);
    }

    public boolean hasPermission(String permission) {
        if (permission == null || permission.isBlank()) {
            return false;
        }
        return permissions.contains(permission.toUpperCase());
    }

    public boolean hasRole(String expectedRole) {
        if (expectedRole == null || expectedRole.isBlank()) {
            return false;
        }
        return role != null && role.equalsIgnoreCase(expectedRole);
    }
}
