package com.learning.content_service.util;

import com.learning.content_service.exception.ForbiddenException;
import java.util.Set;
import lombok.Getter;
import org.springframework.stereotype.Component;

@Component
public class AccessGuard {
    public static final String PERMISSION_READ = "CONTENT_READ";
    public static final String PERMISSION_WRITE = "CONTENT_WRITE";

    private static final Set<String> WRITE_ROLES = Set.of("ADMIN", "TEACHER", "CREATOR");
    private static final Set<String> READ_ROLES = Set.of("ADMIN", "TEACHER", "CREATOR", "STUDENT", "PARENT", "MENTOR");

    public ReadAccess requireRead() {
        TenantContext context = TenantContextHolder.getRequired();
        boolean hasPermission = context.hasPermission(PERMISSION_READ);
        boolean roleAllowed = context.getRole() != null && READ_ROLES.contains(context.getRole().toUpperCase());
        if (!hasPermission && !roleAllowed) {
            throw new ForbiddenException("Read access denied");
        }
        boolean restrictVisibility = !hasPermission && context.hasRole("STUDENT");
        return new ReadAccess(context, restrictVisibility);
    }

    public TenantContext requireWrite() {
        TenantContext context = TenantContextHolder.getRequired();
        boolean hasPermission = context.hasPermission(PERMISSION_WRITE);
        boolean roleAllowed = context.getRole() != null && WRITE_ROLES.contains(context.getRole().toUpperCase());
        if (!hasPermission && !roleAllowed) {
            throw new ForbiddenException("Write access denied");
        }
        return context;
    }

    @Getter
    public static class ReadAccess {
        private final TenantContext context;
        private final boolean restrictToTenantVisibility;

        public ReadAccess(TenantContext context, boolean restrictToTenantVisibility) {
            this.context = context;
            this.restrictToTenantVisibility = restrictToTenantVisibility;
        }
    }
}
