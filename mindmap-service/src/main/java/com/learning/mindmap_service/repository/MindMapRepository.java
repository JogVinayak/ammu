package com.learning.mindmap_service.repository;

import com.learning.mindmap_service.model.entity.MindMap;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MindMapRepository extends JpaRepository<MindMap, UUID> {
    Optional<MindMap> findByMindMapIdAndTenantId(UUID mindMapId, String tenantId);

    List<MindMap> findByTenantIdOrderByUpdatedAtDesc(String tenantId, Pageable pageable);
}
