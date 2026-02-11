package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.Deck;
import com.learning.notes_service.model.enums.DeckStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeckRepository extends JpaRepository<Deck, UUID> {

    Optional<Deck> findByIdAndTenantId(UUID id, UUID tenantId);

    Optional<Deck> findByTenantIdAndNoteId(UUID tenantId, UUID noteId);

    List<Deck> findByTenantIdAndStatus(UUID tenantId, DeckStatus status);

    boolean existsByTenantIdAndNoteId(UUID tenantId, UUID noteId);
}
