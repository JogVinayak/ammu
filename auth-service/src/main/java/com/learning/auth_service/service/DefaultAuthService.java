package com.learning.auth_service.service;

import com.learning.auth_service.model.dto.AccessTokenClaims;
import com.learning.auth_service.model.dto.AuthResponse;
import com.learning.auth_service.model.dto.InviteAcceptRequest;
import com.learning.auth_service.model.dto.InviteRequest;
import com.learning.auth_service.model.dto.InviteResponse;
import com.learning.auth_service.model.dto.LoginRequest;
import com.learning.auth_service.model.dto.LogoutAllRequest;
import com.learning.auth_service.model.dto.LogoutRequest;
import com.learning.auth_service.model.dto.OtpSendRequest;
import com.learning.auth_service.model.dto.OtpSendResponse;
import com.learning.auth_service.model.dto.PasswordChangeRequest;
import com.learning.auth_service.model.dto.PasswordForgotRequest;
import com.learning.auth_service.model.dto.RefreshRequest;
import com.learning.auth_service.model.dto.ResetPasswordRequest;
import com.learning.auth_service.model.dto.ResolveRequest;
import com.learning.auth_service.model.dto.ResolveResponse;
import com.learning.auth_service.model.dto.SignupRequest;
import com.learning.auth_service.model.dto.TokenIntrospectRequest;
import com.learning.auth_service.model.dto.TokenIntrospectResponse;
import com.learning.auth_service.model.dto.VerifyOtpRequest;
import com.learning.auth_service.model.entity.TenantMembership;
import com.learning.auth_service.model.entity.UserIdentity;
import com.learning.auth_service.model.enums.AccountStatus;
import com.learning.auth_service.model.enums.AuthLevel;
import com.learning.auth_service.model.enums.JoinMethod;
import com.learning.auth_service.model.enums.TenantMembershipStatus;
import com.learning.auth_service.repository.TenantMembershipRepository;
import com.learning.auth_service.repository.UserIdentityRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
@RequiredArgsConstructor
public class DefaultAuthService implements AuthService {
    private static final long ACCESS_TOKEN_TTL_SECONDS = 3600L;
    private static final Duration OTP_TTL = Duration.ofMinutes(5);
    private static final Duration INVITE_TTL = Duration.ofDays(2);

    private final UserIdentityRepository userIdentityRepository;
    private final TenantMembershipRepository tenantMembershipRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.profile.url:http://localhost:8083}")
    private String profileServiceUrl;

    @Value("${services.tenant.url:http://localhost:8082}")
    private String tenantServiceUrl;

    @Value("${services.permission.url:http://localhost:8080}")
    private String permissionServiceUrl;

    @Override
    public ResolveResponse resolve(ResolveRequest request) {
        String identifier = request.getIdentifier();
        if (identifier == null || identifier.isBlank()) {
            throw new IllegalArgumentException("Identifier (email or phone) is required");
        }

        // Find user by email or phone
        Optional<UserIdentity> userOpt = userIdentityRepository.findByPrimaryEmailOrPrimaryPhone(identifier, identifier);
        if (userOpt.isEmpty()) {
            throw new RuntimeException("User not found with identifier: " + identifier);
        }

        UserIdentity user = userOpt.get();
        ResolveResponse response = new ResolveResponse();
        response.setUserId(user.getId());
        response.setDisplayName(user.getPrimaryEmail()); // Use email as display name for now

        // Get active tenant memberships
        List<TenantMembership> memberships = tenantMembershipRepository
                .findByUserIdAndStatus(user.getId(), TenantMembershipStatus.ACTIVE);

        List<ResolveResponse.TenantInfo> tenants = new ArrayList<>();
        for (TenantMembership membership : memberships) {
            ResolveResponse.TenantInfo tenantInfo = new ResolveResponse.TenantInfo();
            tenantInfo.setTenantId(membership.getTenantId());

            // Try to get tenant name from tenant service
            try {
                String tenantName = fetchTenantName(membership.getTenantId());
                tenantInfo.setTenantName(tenantName);
            } catch (Exception e) {
                tenantInfo.setTenantName("Tenant " + membership.getTenantId().toString().substring(0, 8));
            }

            // Try to get user type from profile service
            try {
                String userType = fetchUserType(membership.getTenantId(), user.getId());
                tenantInfo.setUserType(userType);
            } catch (Exception e) {
                tenantInfo.setUserType("UNKNOWN");
            }

            tenants.add(tenantInfo);
        }

        response.setTenants(tenants);
        return response;
    }

    private String fetchTenantName(UUID tenantId) {
        try {
            WebClient client = webClientBuilder.baseUrl(tenantServiceUrl).build();
            Map<?, ?> result = client.get()
                    .uri("/v1/tenants/{tenantId}", tenantId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            if (result != null && result.get("name") != null) {
                return result.get("name").toString();
            }
        } catch (Exception e) {
            // Ignore, return default
        }
        return null;
    }

    private Map<String, String> fetchUserProfile(UUID tenantId, UUID userId) {
        Map<String, String> profile = new java.util.HashMap<>();
        profile.put("userType", "UNKNOWN");
        try {
            WebClient client = webClientBuilder.baseUrl(profileServiceUrl).build();
            Map<?, ?> result = client.get()
                    .uri("/v1/tenants/{tenantId}/profiles/by-user/{userId}", tenantId, userId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            if (result != null) {
                if (result.get("userType") != null) {
                    profile.put("userType", result.get("userType").toString());
                }
                if (result.get("displayName") != null) {
                    profile.put("displayName", result.get("displayName").toString());
                }
            }
        } catch (Exception e) {
            // Ignore, return defaults
        }
        return profile;
    }

    private String fetchUserType(UUID tenantId, UUID userId) {
        return fetchUserProfile(tenantId, userId).get("userType");
    }

    @Override
    public AuthResponse signup(SignupRequest request) {
        // Check if user already exists by email
        Optional<UserIdentity> existingUser = Optional.empty();
        if (request.getEmail() != null) {
            existingUser = userIdentityRepository.findByPrimaryEmail(request.getEmail());
        }
        if (existingUser.isEmpty() && request.getPhone() != null) {
            existingUser = userIdentityRepository.findByPrimaryPhone(request.getPhone());
        }

        if (existingUser.isPresent()) {
            // User exists, return existing user ID
            UserIdentity user = existingUser.get();
            return buildAuthResponse(user.getId(), request.getTenantId(), user.getPrimaryEmail(), null);
        }

        // Create new user
        UUID userId = UUID.randomUUID();
        Instant now = Instant.now();
        UserIdentity user = new UserIdentity();
        user.setId(userId);
        user.setPrimaryEmail(request.getEmail());
        user.setPrimaryPhone(request.getPhone());
        user.setPasswordHash(request.getPassword()); // In production, this should be hashed
        user.setStatus(AccountStatus.ACTIVE);
        user.setEmailVerified(false);
        user.setPhoneVerified(false);
        user.setFailedLoginCount(0);
        user.setCreatedAt(now);
        user.setUpdatedAt(now);

        userIdentityRepository.save(user);

        // Create tenant membership
        String userType = request.getUserType() != null ? request.getUserType() : "STUDENT";
        if (request.getTenantId() != null) {
            TenantMembership membership = new TenantMembership();
            membership.setId(UUID.randomUUID());
            membership.setUserId(userId);
            membership.setTenantId(request.getTenantId());
            membership.setStatus(TenantMembershipStatus.ACTIVE);
            membership.setJoinMethod(request.getJoinMethod() != null ? request.getJoinMethod() : JoinMethod.ADMIN_CREATE);
            membership.setCreatedAt(now);
            tenantMembershipRepository.save(membership);

            // Sync: create profile in user-profile-service
            createProfile(request.getTenantId(), userId, request.getEmail(), request.getPhone(), request.getName(), userType);

            // Sync: assign default role in role-permission-service
            assignDefaultRole(request.getTenantId(), userId, userType);
        }

        return buildAuthResponse(userId, request.getTenantId(), request.getEmail(), userType);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        // Try to find user by identifier
        String identifier = request.getIdentifier();
        Optional<UserIdentity> userOpt = userIdentityRepository.findByPrimaryEmailOrPrimaryPhone(identifier, identifier);

        UUID userId;
        UUID tenantId = request.getTenantId();
        String displayName = identifier;
        String userType = null;

        if (userOpt.isPresent()) {
            UserIdentity user = userOpt.get();
            userId = user.getId();
            displayName = user.getPrimaryEmail();

            // If tenantId not provided, try to find first active membership
            if (tenantId == null) {
                List<TenantMembership> memberships = tenantMembershipRepository
                        .findByUserIdAndStatus(userId, TenantMembershipStatus.ACTIVE);
                if (!memberships.isEmpty()) {
                    tenantId = memberships.get(0).getTenantId();
                }
            }

            // Fetch userType and displayName from profile service
            if (tenantId != null) {
                Map<String, String> profile = fetchUserProfile(tenantId, userId);
                userType = profile.get("userType");
                if (profile.get("displayName") != null) {
                    displayName = profile.get("displayName");
                }
            }
        } else {
            // User not found, generate random (mock behavior for backward compatibility)
            userId = UUID.randomUUID();
            // Also generate a default tenant ID for testing if none provided
            if (tenantId == null) {
                tenantId = UUID.randomUUID();
            }
            userType = "TEACHER"; // Default to teacher for mock users
        }

        return buildAuthResponse(userId, tenantId, displayName, userType);
    }

    @Override
    public AuthResponse refreshToken(RefreshRequest request) {
        return buildAuthResponse(UUID.randomUUID(), UUID.randomUUID());
    }

    @Override
    public void logout(LogoutRequest request) {
    }

    @Override
    public void logoutAll(LogoutAllRequest request) {
    }

    @Override
    public OtpSendResponse sendOtp(OtpSendRequest request) {
        OtpSendResponse response = new OtpSendResponse();
        response.setChallengeId(UUID.randomUUID());
        response.setExpiresAt(Instant.now().plus(OTP_TTL));
        return response;
    }

    @Override
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        return buildAuthResponse(UUID.randomUUID(), UUID.randomUUID());
    }

    @Override
    public void forgotPassword(PasswordForgotRequest request) {
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
    }

    @Override
    public void changePassword(PasswordChangeRequest request) {
    }

    @Override
    public InviteResponse createInvite(InviteRequest request) {
        InviteResponse response = new InviteResponse();
        response.setInviteId(UUID.randomUUID());
        response.setExpiresAt(Instant.now().plus(INVITE_TTL));
        return response;
    }

    @Override
    public AuthResponse acceptInvite(InviteAcceptRequest request) {
        UUID tenantId = request.getTenantId() != null ? request.getTenantId() : UUID.randomUUID();
        return buildAuthResponse(UUID.randomUUID(), tenantId);
    }

    @Override
    public TokenIntrospectResponse introspect(TokenIntrospectRequest request) {
        TokenIntrospectResponse response = new TokenIntrospectResponse();
        String token = request.getToken();
        if (token == null || token.isBlank()) {
            response.setActive(false);
            return response;
        }

        AccessTokenClaims claims = new AccessTokenClaims();
        claims.setUserId(UUID.randomUUID());
        claims.setTenantId(UUID.randomUUID());
        claims.setSessionId(UUID.randomUUID());
        claims.setIssuedAt(Instant.now().minusSeconds(60));
        claims.setExpiresAt(Instant.now().plusSeconds(ACCESS_TOKEN_TTL_SECONDS));
        claims.setAuthLevel(AuthLevel.PASSWORD);
        claims.setVersion(1);

        response.setActive(true);
        response.setClaims(claims);
        return response;
    }

    @Override
    public void deleteUser(UUID userId) {
        // In a real implementation, this would delete the user and related data
        userIdentityRepository.deleteById(userId);
    }

    private void createProfile(UUID tenantId, UUID userId, String email, String phone, String name, String userType) {
        try {
            String displayName = name != null ? name : email;
            Map<String, Object> body = Map.of(
                    "userId", userId.toString(),
                    "displayName", displayName,
                    "email", email != null ? email : "",
                    "phone", phone != null ? phone : "",
                    "userType", userType
            );
            webClientBuilder.baseUrl(profileServiceUrl).build()
                    .post()
                    .uri("/v1/tenants/{tenantId}/profiles", tenantId)
                    .header("Content-Type", "application/json")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
        } catch (Exception e) {
            // Log but don't fail signup if profile creation fails
            System.err.println("Failed to create profile in user-profile-service: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private void assignDefaultRole(UUID tenantId, UUID userId, String userType) {
        try {
            // Look up roles for this tenant
            WebClient client = webClientBuilder.baseUrl(permissionServiceUrl).build();
            List<Map<String, Object>> roles = client.get()
                    .uri("/tenants/{tenantId}/roles", tenantId)
                    .retrieve()
                    .bodyToMono(List.class)
                    .block();

            if (roles == null || roles.isEmpty()) {
                return;
            }

            // Find role matching userType (case-insensitive)
            String targetRoleName = userType.toLowerCase();
            Long roleId = null;
            for (Map<String, Object> role : roles) {
                String roleName = role.get("name").toString().toLowerCase();
                if (roleName.equals(targetRoleName) || roleName.contains(targetRoleName)) {
                    roleId = ((Number) role.get("id")).longValue();
                    break;
                }
            }

            if (roleId == null) {
                return;
            }

            // Assign the role
            Map<String, Object> body = Map.of("roleId", roleId);
            client.post()
                    .uri("/tenants/{tenantId}/users/{userId}/roles", tenantId, userId)
                    .header("Content-Type", "application/json")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
        } catch (Exception e) {
            // Log but don't fail signup if role assignment fails
            System.err.println("Failed to assign default role: " + e.getMessage());
        }
    }

    private AuthResponse buildAuthResponse(UUID userId, UUID tenantId) {
        return buildAuthResponse(userId, tenantId, null, null);
    }

    private AuthResponse buildAuthResponse(UUID userId, UUID tenantId, String displayName, String userType) {
        AuthResponse response = new AuthResponse();
        response.setAccessToken(UUID.randomUUID().toString());
        response.setRefreshToken(UUID.randomUUID().toString());
        response.setExpiresIn(ACCESS_TOKEN_TTL_SECONDS);
        response.setUserId(userId);
        response.setTenantId(tenantId);
        response.setDisplayName(displayName);
        response.setUserType(userType);
        return response;
    }
}
