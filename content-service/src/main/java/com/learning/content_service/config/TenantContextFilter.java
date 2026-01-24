package com.learning.content_service.config;

import com.learning.content_service.exception.BadRequestException;
import com.learning.content_service.exception.ForbiddenException;
import com.learning.content_service.util.TenantContext;
import com.learning.content_service.util.TenantContextHolder;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerExceptionResolver;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
@RequiredArgsConstructor
public class TenantContextFilter extends OncePerRequestFilter {
    private final JwtService jwtService;
    @Qualifier("handlerExceptionResolver")
    private final HandlerExceptionResolver handlerExceptionResolver;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {
        if (shouldSkip(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            String tenantId = requireHeader(request, "X-Tenant-Id");
            String userIdHeader = requireHeader(request, "X-User-Id");
            String role = requireHeader(request, "X-Role");

            UUID userId = parseUserId(userIdHeader);
            Set<String> permissions = parsePermissions(request.getHeader("X-Permissions"));

            String authorization = request.getHeader("Authorization");
            if (authorization != null && !authorization.isBlank()) {
                if (!authorization.startsWith("Bearer ")) {
                    throw new ForbiddenException("Invalid authorization header");
                }
                String token = authorization.substring("Bearer ".length()).trim();
                jwtService.validate(token);
            }

            TenantContext context = new TenantContext(tenantId, userId, role.trim().toUpperCase(), permissions);
            TenantContextHolder.set(context);

            filterChain.doFilter(request, response);
        } catch (RuntimeException ex) {
            TenantContextHolder.clear();
            handlerExceptionResolver.resolveException(request, response, null, ex);
        } finally {
            TenantContextHolder.clear();
        }
    }

    private boolean shouldSkip(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (path == null) {
            return false;
        }
        if (path.startsWith("/actuator")) {
            return true;
        }
        return "OPTIONS".equalsIgnoreCase(request.getMethod());
    }

    private String requireHeader(HttpServletRequest request, String headerName) {
        String value = request.getHeader(headerName);
        if (value == null || value.isBlank()) {
            throw new BadRequestException(headerName + " header is required");
        }
        return value.trim();
    }

    private UUID parseUserId(String userIdHeader) {
        try {
            return UUID.fromString(userIdHeader.trim());
        } catch (IllegalArgumentException ex) {
            throw new BadRequestException("X-User-Id must be a valid UUID");
        }
    }

    private Set<String> parsePermissions(String permissionsHeader) {
        if (permissionsHeader == null || permissionsHeader.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(permissionsHeader.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .map(String::toUpperCase)
                .collect(Collectors.toSet());
    }
}
