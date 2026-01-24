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

public interface AuthService {
    AuthResponse signup(SignupRequest request);

    InviteResponse createInvite(InviteRequest request);

    AuthResponse acceptInvite(InviteAcceptRequest request);

    OtpSendResponse sendOtp(OtpSendRequest request);

    AuthResponse verifyOtp(VerifyOtpRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshToken(RefreshRequest request);

    void logout(LogoutRequest request);

    void logoutAll(LogoutAllRequest request);

    void forgotPassword(PasswordForgotRequest request);

    void resetPassword(ResetPasswordRequest request);

    void changePassword(PasswordChangeRequest request);

    TokenIntrospectResponse introspect(TokenIntrospectRequest request);
}
