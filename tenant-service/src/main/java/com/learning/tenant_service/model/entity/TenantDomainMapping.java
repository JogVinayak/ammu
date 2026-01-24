package com.learning.tenant_service.model.entity;

import com.learning.tenant_service.model.enums.DomainType;
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
@Table(name = "tenant_domain_mappings")
@Getter
@Setter
@NoArgsConstructor
public class TenantDomainMapping {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "hostname", nullable = false, unique = true)
    private String hostname;

    @Enumerated(EnumType.STRING)
    private DomainType type;

    @Column(name = "verified")
    private boolean verified;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
