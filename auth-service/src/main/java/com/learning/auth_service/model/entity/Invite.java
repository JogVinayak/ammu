package com.learning.auth_service.model.entity;

import com.learning.auth_service.model.enums.InviteStatus;
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
@Table(name = "invites")
@Getter
@Setter
@NoArgsConstructor
public class Invite {
    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(name = "email_or_phone")
    private String emailOrPhone;

    @Column(name = "invited_role_hints")
    private String invitedRoleHints;

    @Enumerated(EnumType.STRING)
    private InviteStatus status;

    @Column(name = "token_hash")
    private String tokenHash;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "invited_by")
    private UUID invitedBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "accepted_at")
    private Instant acceptedAt;

}
