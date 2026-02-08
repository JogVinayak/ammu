package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.Mcq;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface McqRepository extends JpaRepository<Mcq, UUID> {

    List<Mcq> findByTenantIdAndNoteIdOrderByPositionAsc(UUID tenantId, UUID noteId);

    List<Mcq> findByTenantIdAndNoteIdAndDifficultyOrderByPositionAsc(
            UUID tenantId, UUID noteId, String difficulty);

    Optional<Mcq> findByIdAndTenantId(UUID id, UUID tenantId);

    @Query("SELECT COALESCE(MAX(m.position), 0) FROM Mcq m WHERE m.tenantId = :tenantId AND m.noteId = :noteId")
    Integer findMaxPosition(@Param("tenantId") UUID tenantId, @Param("noteId") UUID noteId);

    @Modifying
    @Transactional
    @Query("DELETE FROM Mcq m WHERE m.tenantId = :tenantId AND m.noteId = :noteId")
    void deleteByTenantIdAndNoteId(@Param("tenantId") UUID tenantId, @Param("noteId") UUID noteId);

    long countByTenantIdAndNoteId(UUID tenantId, UUID noteId);

    long countByTenantIdAndNoteIdAndDifficulty(UUID tenantId, UUID noteId, String difficulty);
}
