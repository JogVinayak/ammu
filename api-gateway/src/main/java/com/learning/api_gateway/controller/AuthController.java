package com.learning.api_gateway.controller;

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
import com.learning.api_gateway.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/auth")
public class AuthController {
    private final AuthService authService;

    @PostMapping("/signup")
    public AuthResponse signup(@RequestBody SignupRequest request) {
        return authService.signup(request);
    }

    @PostMapping("/invite")
    public InviteResponse invite(@RequestBody InviteRequest request) {
        return authService.createInvite(request);
    }

    @PostMapping("/invite/accept")
    public AuthResponse acceptInvite(@RequestBody InviteAcceptRequest request) {
        return authService.acceptInvite(request);
    }

    @PostMapping("/otp/send")
    public OtpSendResponse sendOtp(@RequestBody OtpSendRequest request) {
        return authService.sendOtp(request);
    }

    @PostMapping("/otp/verify")
    public AuthResponse verifyOtp(@RequestBody VerifyOtpRequest request) {
        return authService.verifyOtp(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/token/refresh")
    public AuthResponse refresh(@RequestBody RefreshRequest request) {
        return authService.refreshToken(request);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody LogoutRequest request) {
        authService.logout(request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/logout/all")
    public ResponseEntity<Void> logoutAll(@RequestBody LogoutAllRequest request) {
        authService.logoutAll(request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/password/forgot")
    public ResponseEntity<Void> forgotPassword(@RequestBody PasswordForgotRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/password/reset")
    public ResponseEntity<Void> resetPassword(@RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/password/change")
    public ResponseEntity<Void> changePassword(@RequestBody PasswordChangeRequest request) {
        authService.changePassword(request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/token/introspect")
    public TokenIntrospectResponse introspect(@RequestBody TokenIntrospectRequest request) {
        return authService.introspect(request);
    }
}
