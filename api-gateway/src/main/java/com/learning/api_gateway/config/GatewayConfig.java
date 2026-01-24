package com.learning.api_gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.server.RequestPredicate;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.RouterFunctions;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

import java.util.regex.Pattern;

@Configuration
public class GatewayConfig {

    @Value("${services.auth.url:http://localhost:8081}")
    private String authServiceUrl;

    @Value("${services.tenant.url:http://localhost:8082}")
    private String tenantServiceUrl;

    @Value("${services.profile.url:http://localhost:8083}")
    private String profileServiceUrl;

    @Value("${services.permission.url:http://localhost:8080}")
    private String permissionServiceUrl;

    // Patterns for profile service routes (under /v1/tenants/{tenantId}/...)
    private static final Pattern PROFILE_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/profiles(/.*)?$");
    private static final Pattern RELATIONSHIP_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/relationships(/.*)?$");
    // Profile service: /v1/tenants/{tenantId}/users/{userId}/student-profile, /preferences
    private static final Pattern USER_STUDENT_PROFILE_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/users/[^/]+/(student-profile|preferences)$");

    // Patterns for permission service routes
    private static final Pattern PERMISSIONS_PATTERN = Pattern.compile("^/v1/permissions(/.*)?$");
    private static final Pattern PERMISSION_SCOPES_PATTERN = Pattern.compile("^/v1/permission-scopes(/.*)?$");
    private static final Pattern AUTHORIZE_PATTERN = Pattern.compile("^/v1/authorize(/.*)?$");
    // Permission service routes under /v1/tenants/{tenantId}/...
    private static final Pattern ROLES_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/roles(/.*)?$");
    private static final Pattern POLICIES_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/policies(/.*)?$");
    // Permission service: /v1/tenants/{tenantId}/users/{userId}/roles
    private static final Pattern USER_ROLES_PATTERN = Pattern.compile("^/v1/tenants/[^/]+/users/[^/]+/roles(/.*)?$");

    @Bean
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder();
    }

    @Bean
    public RouterFunction<ServerResponse> routerFunction(WebClient.Builder webClientBuilder) {
        // Custom predicate for profile service routes
        RequestPredicate isProfileServiceRoute = request -> {
            String path = request.path();
            return PROFILE_PATTERN.matcher(path).matches() ||
                   RELATIONSHIP_PATTERN.matcher(path).matches() ||
                   USER_STUDENT_PROFILE_PATTERN.matcher(path).matches();
        };

        // Custom predicate for permission service routes
        RequestPredicate isPermissionRoute = request -> {
            String path = request.path();
            return PERMISSIONS_PATTERN.matcher(path).matches() ||
                   PERMISSION_SCOPES_PATTERN.matcher(path).matches() ||
                   AUTHORIZE_PATTERN.matcher(path).matches();
        };

        // Custom predicate for permission service routes under /v1/tenants/
        RequestPredicate isPermissionTenantRoute = request -> {
            String path = request.path();
            return ROLES_PATTERN.matcher(path).matches() ||
                   POLICIES_PATTERN.matcher(path).matches() ||
                   USER_ROLES_PATTERN.matcher(path).matches();
        };

        return RouterFunctions
            .route()
            // Auth Service routes: /v1/auth/** -> /auth/**
            .path("/v1/auth/**", builder -> builder
                .GET("/**", req -> proxyWithRewrite(req, authServiceUrl, "/v1/auth", "/auth", webClientBuilder))
                .POST("/**", req -> proxyWithRewrite(req, authServiceUrl, "/v1/auth", "/auth", webClientBuilder))
                .PUT("/**", req -> proxyWithRewrite(req, authServiceUrl, "/v1/auth", "/auth", webClientBuilder))
                .DELETE("/**", req -> proxyWithRewrite(req, authServiceUrl, "/v1/auth", "/auth", webClientBuilder))
            )
            // Tenant Service routes - /v1/resolve
            .GET("/v1/resolve", req -> proxy(req, tenantServiceUrl, webClientBuilder))

            // Permission Service routes: /v1/permissions/**, /v1/permission-scopes/**, /v1/authorize/**
            // These strip /v1 prefix when forwarding
            .GET(isPermissionRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .POST(isPermissionRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .PUT(isPermissionRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .DELETE(isPermissionRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))

            // Permission Service tenant routes (must come BEFORE profile and generic tenant routes)
            // Routes: /v1/tenants/{tenantId}/roles/**, /v1/tenants/{tenantId}/policies/**, /v1/tenants/{tenantId}/users/{userId}/roles/**
            .GET(isPermissionTenantRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .POST(isPermissionTenantRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .PUT(isPermissionTenantRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))
            .DELETE(isPermissionTenantRoute, req -> proxyWithRewrite(req, permissionServiceUrl, "/v1", "", webClientBuilder))

            // Profile Service routes (must come BEFORE generic /v1/tenants/**)
            // Routes: /v1/tenants/{tenantId}/profiles/**, /v1/tenants/{tenantId}/relationships/**, /v1/tenants/{tenantId}/users/{userId}/student-profile
            .GET(isProfileServiceRoute, req -> proxy(req, profileServiceUrl, webClientBuilder))
            .POST(isProfileServiceRoute, req -> proxy(req, profileServiceUrl, webClientBuilder))
            .PUT(isProfileServiceRoute, req -> proxy(req, profileServiceUrl, webClientBuilder))
            .DELETE(isProfileServiceRoute, req -> proxy(req, profileServiceUrl, webClientBuilder))

            // Tenant Service routes - /v1/tenants/** (generic, after specific routes)
            .path("/v1/tenants/**", builder -> builder
                .GET("/**", req -> proxy(req, tenantServiceUrl, webClientBuilder))
                .POST("/**", req -> proxy(req, tenantServiceUrl, webClientBuilder))
                .PUT("/**", req -> proxy(req, tenantServiceUrl, webClientBuilder))
                .DELETE("/**", req -> proxy(req, tenantServiceUrl, webClientBuilder))
            )
            .build();
    }

    private Mono<ServerResponse> proxy(ServerRequest request, String targetBaseUrl, WebClient.Builder webClientBuilder) {
        return proxyWithRewrite(request, targetBaseUrl, null, null, webClientBuilder);
    }

    private Mono<ServerResponse> proxyWithRewrite(ServerRequest request, String targetBaseUrl,
            String stripPrefix, String addPrefix, WebClient.Builder webClientBuilder) {
        WebClient webClient = webClientBuilder.baseUrl(targetBaseUrl).build();

        String path = request.path();

        // Rewrite path if needed
        if (stripPrefix != null && path.startsWith(stripPrefix)) {
            path = path.substring(stripPrefix.length());
            if (addPrefix != null && !addPrefix.isEmpty()) {
                path = addPrefix + path;
            }
        }

        String query = request.uri().getRawQuery();
        String fullPath = query != null ? path + "?" + query : path;

        HttpMethod method = HttpMethod.valueOf(request.method().name());

        WebClient.RequestBodySpec requestSpec = webClient
            .method(method)
            .uri(fullPath)
            .headers(headers -> {
                request.headers().asHttpHeaders().forEach((name, values) -> {
                    // Don't forward hop-by-hop headers
                    if (!name.equalsIgnoreCase("Host") &&
                        !name.equalsIgnoreCase("Connection") &&
                        !name.equalsIgnoreCase("Content-Length")) {
                        headers.addAll(name, values);
                    }
                });
            });

        Mono<WebClient.ResponseSpec> responseMono;
        if (method == HttpMethod.POST || method == HttpMethod.PUT || method == HttpMethod.PATCH) {
            responseMono = request.bodyToMono(byte[].class)
                .defaultIfEmpty(new byte[0])
                .map(body -> requestSpec.bodyValue(body).retrieve());
        } else {
            responseMono = Mono.just(requestSpec.retrieve());
        }

        return responseMono.flatMap(responseSpec ->
            responseSpec.toEntity(byte[].class)
                .flatMap(entity -> {
                    ServerResponse.BodyBuilder responseBuilder = ServerResponse
                        .status(entity.getStatusCode());

                    entity.getHeaders().forEach((name, values) -> {
                        if (!name.equalsIgnoreCase("Transfer-Encoding")) {
                            responseBuilder.header(name, values.toArray(new String[0]));
                        }
                    });

                    byte[] body = entity.getBody();
                    if (body != null && body.length > 0) {
                        return responseBuilder.bodyValue(body);
                    }
                    return responseBuilder.build();
                })
                .onErrorResume(e -> ServerResponse.status(502).bodyValue("Gateway error: " + e.getMessage()))
        );
    }
}
