package com.learning.graph_relations_service.model.entity;

import com.learning.graph_relations_service.model.enums.EdgeSignalType;
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
@Table(name = "edge_signals")
@Getter
@Setter
@NoArgsConstructor
public class EdgeSignal {
    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(name = "graph_id")
    private UUID graphId;

    @Column(name = "edge_id")
    private UUID edgeId;

    @Column(name = "user_id")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "signal_type")
    private EdgeSignalType signalType;

    @Column(name = "signal_value")
    private Double signalValue;

    @Column(name = "occurred_at")
    private Instant occurredAt;

    @Column(columnDefinition = "jsonb")
    private String meta;
}
