package com.learning.content_service.config;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.learning.content_service.exception.ForbiddenException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtService {
    private final String secret;
    private final JWTVerifier verifier;

    public JwtService(@Value("${content.jwt.secret:}") String secret) {
        this.secret = secret == null ? "" : secret.trim();
        if (this.secret.isEmpty()) {
            this.verifier = null;
        } else {
            Algorithm algorithm = Algorithm.HMAC256(this.secret);
            this.verifier = JWT.require(algorithm).build();
        }
    }

    public void validate(String token) {
        if (token == null || token.isBlank()) {
            throw new ForbiddenException("Missing bearer token");
        }
        if (verifier == null) {
            throw new ForbiddenException("JWT secret not configured");
        }
        try {
            verifier.verify(token);
        } catch (JWTVerificationException ex) {
            throw new ForbiddenException("Invalid bearer token");
        }
    }
}
