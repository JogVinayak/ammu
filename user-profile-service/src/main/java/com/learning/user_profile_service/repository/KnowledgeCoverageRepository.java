package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.KnowledgeCoverage;
import com.learning.user_profile_service.model.enums.MasteryLevel;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface KnowledgeCoverageRepository extends JpaRepository<KnowledgeCoverage, UUID> {
    Optional<KnowledgeCoverage> findByTenantIdAndUserIdAndMindmapIdAndNodeId(
            UUID tenantId, UUID userId, UUID mindmapId, UUID nodeId);

    List<KnowledgeCoverage> findByTenantIdAndUserIdAndMindmapId(
            UUID tenantId, UUID userId, UUID mindmapId);

    List<KnowledgeCoverage> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<KnowledgeCoverage> findByUserIdAndNextReviewAtBeforeOrderByNextReviewAtAsc(
            UUID userId, Instant before);

    long countByTenantIdAndUserIdAndMindmapIdAndMasteryLevel(
            UUID tenantId, UUID userId, UUID mindmapId, MasteryLevel masteryLevel);

    @Query("SELECT COUNT(k) FROM KnowledgeCoverage k WHERE k.tenantId = :tenantId AND k.userId = :userId " +
           "AND k.mindmapId = :mindmapId AND k.masteryLevel IN :levels")
    long countByTenantIdAndUserIdAndMindmapIdAndMasteryLevelIn(
            @Param("tenantId") UUID tenantId,
            @Param("userId") UUID userId,
            @Param("mindmapId") UUID mindmapId,
            @Param("levels") List<MasteryLevel> levels);
}
