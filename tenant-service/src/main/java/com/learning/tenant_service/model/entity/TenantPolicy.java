package com.learning.tenant_service.model.entity;

import com.learning.tenant_service.model.enums.AuthMethod;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "tenant_policies")
@Getter
@Setter
@NoArgsConstructor
public class TenantPolicy {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false, unique = true)
    private UUID tenantId;

    @Column(name = "allow_self_signup")
    private boolean allowSelfSignup;

    @Column(name = "require_admin_approval")
    private boolean requireAdminApproval;

    @ElementCollection
    @CollectionTable(name = "tenant_policy_auth_methods", joinColumns = @JoinColumn(name = "tenant_policy_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "auth_method")
    private Set<AuthMethod> allowedAuthMethods;

    @Column(name = "allowed_signup_domains")
    private String allowedSignupDomains;

    @Column(name = "session_max_days")
    private Integer sessionMaxDays;

    @Column(name = "quiet_hours_start")
    private String quietHoursStart;

    @Column(name = "quiet_hours_end")
    private String quietHoursEnd;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "extra", columnDefinition = "jsonb")
    private String extra;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
