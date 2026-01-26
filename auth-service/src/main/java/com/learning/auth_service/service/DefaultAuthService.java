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
import com.learning.auth_service.model.dto.SignupRequest;
import com.learning.auth_service.model.dto.TokenIntrospectRequest;
import com.learning.auth_service.model.dto.TokenIntrospectResponse;
import com.learning.auth_service.model.dto.VerifyOtpRequest;
import com.learning.auth_service.model.enums.AuthLevel;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class DefaultAuthService implements AuthService {
    private static final long ACCESS_TOKEN_TTL_SECONDS = 3600L;
    private static final Duration OTP_TTL = Duration.ofMinutes(5);
    private static final Duration INVITE_TTL = Duration.ofDays(2);

    @Override
    public AuthResponse signup(SignupRequest request) {
        UUID userId = UUID.randomUUID();
        return buildAuthResponse(userId, request.getTenantId());
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        UUID userId = UUID.randomUUID();
        return buildAuthResponse(userId, request.getTenantId());
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
        // Mock implementation - no actual persistence to delete from
        // In a real implementation, this would delete the user and related data
    }

    private AuthResponse buildAuthResponse(UUID userId, UUID tenantId) {
        AuthResponse response = new AuthResponse();
        response.setAccessToken(UUID.randomUUID().toString());
        response.setRefreshToken(UUID.randomUUID().toString());
        response.setExpiresIn(ACCESS_TOKEN_TTL_SECONDS);
        response.setUserId(userId);
        response.setTenantId(tenantId);
        return response;
    }
}
