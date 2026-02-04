package com.learning.auth_service.service;

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
import com.learning.auth_service.model.dto.ResolveRequest;
import com.learning.auth_service.model.dto.ResolveResponse;
import com.learning.auth_service.model.dto.VerifyOtpRequest;
import java.util.UUID;

public interface AuthService {
    ResolveResponse resolve(ResolveRequest request);

    AuthResponse signup(SignupRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshToken(RefreshRequest request);

    void logout(LogoutRequest request);

    void logoutAll(LogoutAllRequest request);

    OtpSendResponse sendOtp(OtpSendRequest request);

    AuthResponse verifyOtp(VerifyOtpRequest request);

    void forgotPassword(PasswordForgotRequest request);

    void resetPassword(ResetPasswordRequest request);

    void changePassword(PasswordChangeRequest request);

    InviteResponse createInvite(InviteRequest request);

    AuthResponse acceptInvite(InviteAcceptRequest request);

    TokenIntrospectResponse introspect(TokenIntrospectRequest request);

    void deleteUser(UUID userId);
}
