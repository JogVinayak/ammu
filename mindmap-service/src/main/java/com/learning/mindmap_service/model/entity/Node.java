package com.learning.mindmap_service.model.entity;

import com.learning.mindmap_service.model.enums.NodeType;
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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(
        name = "nodes",
        indexes = {
            @Index(name = "idx_nodes_tenant_map", columnList = "tenant_id,mind_map_id"),
            @Index(name = "idx_nodes_tenant_title", columnList = "tenant_id,title")
        })
@Getter
@Setter
@NoArgsConstructor
public class Node {
    @Id
    @Column(name = "node_id")
    private UUID nodeId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "mind_map_id", nullable = false)
    private UUID mindMapId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private NodeType type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(name = "body_markdown", columnDefinition = "text")
    private String bodyMarkdown;

    @Column(name = "content_id")
    private UUID contentId;

    @Column(name = "content_version_id")
    private UUID contentVersionId;

    @Column(name = "pos_x")
    private Double posX;

    @Column(name = "pos_y")
    private Double posY;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "meta_json", columnDefinition = "jsonb")
    private String metaJson;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
