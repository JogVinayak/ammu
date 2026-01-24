package com.learning.auth_service.model.entity;

import com.learning.auth_service.model.enums.ChallengeChannel;
import com.learning.auth_service.model.enums.ChallengePurpose;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "verification_challenges")
@Getter
@Setter
@NoArgsConstructor
public class VerificationChallenge {
    @Id
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Enumerated(EnumType.STRING)
    private ChallengeChannel channel;

    @Enumerated(EnumType.STRING)
    private ChallengePurpose purpose;

    private String target;

    @Column(name = "otp_hash")
    private String otpHash;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "max_attempts")
    private int maxAttempts;

    @Column(name = "attempts_used")
    private int attemptsUsed;

    @Column(name = "consumed_at")
    private Instant consumedAt;

    @Column(name = "created_at")
    private Instant createdAt;

}
