package com.learning.mindmap_service.repository;

import com.learning.mindmap_service.model.entity.MindMapVersion;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MindMapVersionRepository extends JpaRepository<MindMapVersion, UUID> {
    Optional<MindMapVersion> findTopByMindMapIdOrderByVersionNumberDesc(UUID mindMapId);
}
