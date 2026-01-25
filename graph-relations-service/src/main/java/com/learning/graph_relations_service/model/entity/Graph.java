package com.learning.graph_relations_service.model.entity;

import com.learning.graph_relations_service.model.enums.GraphScopeType;
import com.learning.graph_relations_service.model.enums.GraphStatus;
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
@Table(name = "graphs")
@Getter
@Setter
@NoArgsConstructor
public class Graph {
    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type")
    private GraphScopeType scopeType;

    @Column(name = "scope_id")
    private UUID scopeId;

    private String name;

    private String description;

    @Enumerated(EnumType.STRING)
    private GraphStatus status;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
