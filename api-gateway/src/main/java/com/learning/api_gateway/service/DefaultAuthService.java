package com.learning.api_gateway.service;

import com.learning.api_gateway.model.dto.AuthResponse;
import com.learning.api_gateway.model.dto.InviteAcceptRequest;
import com.learning.api_gateway.model.dto.InviteRequest;
import com.learning.api_gateway.model.dto.InviteResponse;
import com.learning.api_gateway.model.dto.LoginRequest;
import com.learning.api_gateway.model.dto.LogoutAllRequest;
import com.learning.api_gateway.model.dto.LogoutRequest;
import com.learning.api_gateway.model.dto.OtpSendRequest;
import com.learning.api_gateway.model.dto.OtpSendResponse;
import com.learning.api_gateway.model.dto.PasswordChangeRequest;
import com.learning.api_gateway.model.dto.PasswordForgotRequest;
import com.learning.api_gateway.model.dto.RefreshRequest;
import com.learning.api_gateway.model.dto.ResetPasswordRequest;
import com.learning.api_gateway.model.dto.SignupRequest;
import com.learning.api_gateway.model.dto.TokenIntrospectRequest;
import com.learning.api_gateway.model.dto.TokenIntrospectResponse;
import com.learning.api_gateway.model.dto.VerifyOtpRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@RequiredArgsConstructor
@Service
public class DefaultAuthService implements AuthService {
    private final RestClient authServiceClient;

    @Override
    public AuthResponse signup(SignupRequest request) {
        return authServiceClient.post()
                .uri("/auth/signup")
                .body(request)
                .retrieve()
                .body(AuthResponse.class);
    }

    @Override
    public InviteResponse createInvite(InviteRequest request) {
        return authServiceClient.post()
                .uri("/auth/invite")
                .body(request)
                .retrieve()
                .body(InviteResponse.class);
    }

    @Override
    public AuthResponse acceptInvite(InviteAcceptRequest request) {
        return authServiceClient.post()
                .uri("/auth/invite/accept")
                .body(request)
                .retrieve()
                .body(AuthResponse.class);
    }

    @Override
    public OtpSendResponse sendOtp(OtpSendRequest request) {
        return authServiceClient.post()
                .uri("/auth/otp/send")
                .body(request)
                .retrieve()
                .body(OtpSendResponse.class);
    }

    @Override
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        return authServiceClient.post()
                .uri("/auth/otp/verify")
                .body(request)
                .retrieve()
                .body(AuthResponse.class);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        return authServiceClient.post()
                .uri("/auth/login")
                .body(request)
                .retrieve()
                .body(AuthResponse.class);
    }

    @Override
    public AuthResponse refreshToken(RefreshRequest request) {
        return authServiceClient.post()
                .uri("/auth/token/refresh")
                .body(request)
                .retrieve()
                .body(AuthResponse.class);
    }

    @Override
    public void logout(LogoutRequest request) {
        authServiceClient.post()
                .uri("/auth/logout")
                .body(request)
                .retrieve()
                .toBodilessEntity();
    }

    @Override
    public void logoutAll(LogoutAllRequest request) {
        authServiceClient.post()
                .uri("/auth/logout/all")
                .body(request)
                .retrieve()
                .toBodilessEntity();
    }

    @Override
    public void forgotPassword(PasswordForgotRequest request) {
        authServiceClient.post()
                .uri("/auth/password/forgot")
                .body(request)
                .retrieve()
                .toBodilessEntity();
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
        authServiceClient.post()
                .uri("/auth/password/reset")
                .body(request)
                .retrieve()
                .toBodilessEntity();
    }

    @Override
    public void changePassword(PasswordChangeRequest request) {
        authServiceClient.post()
                .uri("/auth/password/change")
                .body(request)
                .retrieve()
                .toBodilessEntity();
    }

    @Override
    public TokenIntrospectResponse introspect(TokenIntrospectRequest request) {
        return authServiceClient.post()
                .uri("/auth/token/introspect")
                .body(request)
                .retrieve()
                .body(TokenIntrospectResponse.class);
    }
}
