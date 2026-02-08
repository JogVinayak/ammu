package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.Flashcard;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface FlashcardRepository extends JpaRepository<Flashcard, UUID> {

    List<Flashcard> findByTenantIdAndNoteIdOrderByPositionAsc(UUID tenantId, UUID noteId);

    List<Flashcard> findByTenantIdAndNoteIdAndDifficultyOrderByPositionAsc(
            UUID tenantId, UUID noteId, String difficulty);

    Optional<Flashcard> findByIdAndTenantId(UUID id, UUID tenantId);

    long countByTenantIdAndNoteIdAndDifficulty(UUID tenantId, UUID noteId, String difficulty);

    @Query("SELECT COALESCE(MAX(f.position), 0) FROM Flashcard f WHERE f.tenantId = :tenantId AND f.noteId = :noteId")
    Integer findMaxPosition(@Param("tenantId") UUID tenantId, @Param("noteId") UUID noteId);

    @Modifying
    @Transactional
    @Query("DELETE FROM Flashcard f WHERE f.tenantId = :tenantId AND f.noteId = :noteId")
    void deleteByTenantIdAndNoteId(@Param("tenantId") UUID tenantId, @Param("noteId") UUID noteId);

    long countByTenantIdAndNoteId(UUID tenantId, UUID noteId);
}
