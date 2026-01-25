package com.learning.mindmap_service.model.entity;

import com.learning.mindmap_service.model.enums.EdgeRelation;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "edges",
        indexes = {
            @Index(name = "idx_edges_tenant_map", columnList = "tenant_id,mind_map_id"),
            @Index(name = "idx_edges_expires", columnList = "tenant_id,expires_at"),
            @Index(name = "idx_edges_from", columnList = "tenant_id,from_node_id"),
            @Index(name = "idx_edges_to", columnList = "tenant_id,to_node_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class Edge {
    @Id
    @Column(name = "edge_id")
    private UUID edgeId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "mind_map_id", nullable = false)
    private UUID mindMapId;

    @Column(name = "from_node_id", nullable = false)
    private UUID fromNodeId;

    @Column(name = "to_node_id", nullable = false)
    private UUID toNodeId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EdgeRelation relation;

    @Column(name = "weight")
    private Double weight;

    @Column(name = "strength")
    private Double strength;

    @Column(name = "ttl_seconds")
    private Long ttlSeconds;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
