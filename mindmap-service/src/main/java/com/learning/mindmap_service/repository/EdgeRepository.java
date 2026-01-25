package com.learning.mindmap_service.repository;

import com.learning.mindmap_service.model.entity.Edge;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EdgeRepository extends JpaRepository<Edge, UUID> {
    Optional<Edge> findByEdgeIdAndTenantIdAndMindMapId(UUID edgeId, String tenantId, UUID mindMapId);

    List<Edge> findByTenantIdAndMindMapId(String tenantId, UUID mindMapId);

    void deleteByEdgeIdAndTenantIdAndMindMapId(UUID edgeId, String tenantId, UUID mindMapId);

    void deleteByTenantIdAndMindMapIdAndFromNodeId(String tenantId, UUID mindMapId, UUID fromNodeId);

    void deleteByTenantIdAndMindMapIdAndToNodeId(String tenantId, UUID mindMapId, UUID toNodeId);

    @Query("select e from Edge e where e.tenantId = :tenantId and ((e.expiresAt is not null and e.expiresAt <= :now) or (e.strength is not null and e.strength < :threshold))")
    Page<Edge> findWeakEdges(
            @Param("tenantId") String tenantId,
            @Param("now") Instant now,
            @Param("threshold") Double threshold,
            Pageable pageable);
}
