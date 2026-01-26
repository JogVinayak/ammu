package com.learning.auth_service.controller;

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
import com.learning.auth_service.service.AuthService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/auth")
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

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUser(@PathVariable UUID userId) {
        authService.deleteUser(userId);
        return ResponseEntity.noContent().build();
    }
}
