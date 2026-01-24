package com.learning.content_service.util;

import com.learning.content_service.exception.ForbiddenException;

public final class TenantContextHolder {
    private static final ThreadLocal<TenantContext> CONTEXT = new ThreadLocal<>();

    private TenantContextHolder() {
    }

    public static void set(TenantContext context) {
        CONTEXT.set(context);
    }

    public static TenantContext get() {
        return CONTEXT.get();
    }

    public static TenantContext getRequired() {
        TenantContext context = CONTEXT.get();
        if (context == null) {
            throw new ForbiddenException("Missing tenant context");
        }
        return context;
    }

    public static void clear() {
        CONTEXT.remove();
    }
}
