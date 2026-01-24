package com.learning.auth_service.model.entity;

import com.learning.auth_service.model.enums.JoinMethod;
import com.learning.auth_service.model.enums.TenantMembershipStatus;
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
@Table(name = "tenant_memberships")
@Getter
@Setter
@NoArgsConstructor
public class TenantMembership {
    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(name = "user_id")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    private TenantMembershipStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "join_method")
    private JoinMethod joinMethod;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "approved_at")
    private Instant approvedAt;

    @Column(name = "approved_by")
    private UUID approvedBy;

}
