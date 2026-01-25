package com.learning.mindmap_service.repository;

import com.learning.mindmap_service.model.entity.Node;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NodeRepository extends JpaRepository<Node, UUID> {
    Optional<Node> findByNodeIdAndTenantIdAndMindMapId(UUID nodeId, String tenantId, UUID mindMapId);

    List<Node> findByTenantIdAndMindMapId(String tenantId, UUID mindMapId);

    Page<Node> findByTenantIdAndMindMapIdAndTitleContainingIgnoreCase(
            String tenantId, UUID mindMapId, String title, Pageable pageable);

    void deleteByNodeIdAndTenantIdAndMindMapId(UUID nodeId, String tenantId, UUID mindMapId);
}
