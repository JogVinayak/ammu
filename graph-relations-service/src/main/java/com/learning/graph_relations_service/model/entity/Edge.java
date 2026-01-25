package com.learning.graph_relations_service.model.entity;

import com.learning.graph_relations_service.model.enums.RelationType;
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
@Table(name = "edges")
@Getter
@Setter
@NoArgsConstructor
public class Edge {
    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(name = "graph_id")
    private UUID graphId;

    @Column(name = "from_node_id")
    private UUID fromNodeId;

    @Column(name = "to_node_id")
    private UUID toNodeId;

    @Enumerated(EnumType.STRING)
    @Column(name = "relation_type")
    private RelationType relationType;

    private boolean directed;

    private double strength;

    @Column(name = "ttl_hours")
    private int ttlHours;

    @Column(name = "last_reinforced_at")
    private Instant lastReinforcedAt;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;

    @Column(columnDefinition = "jsonb")
    private String meta;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
