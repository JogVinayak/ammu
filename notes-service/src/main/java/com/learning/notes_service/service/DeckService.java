package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.CreateDeckRequest;
import com.learning.notes_service.model.dto.DeckCompositionResponse;
import com.learning.notes_service.model.dto.DeckResponse;
import com.learning.notes_service.model.dto.UpdateDeckRequest;
import java.util.UUID;

public interface DeckService {

    DeckResponse create(UUID tenantId, UUID noteId, CreateDeckRequest request);

    DeckResponse getByNoteId(UUID tenantId, UUID noteId);

    DeckResponse update(UUID tenantId, UUID noteId, UUID deckId, UpdateDeckRequest request);

    void delete(UUID tenantId, UUID noteId, UUID deckId);

    DeckCompositionResponse validateComposition(UUID tenantId, UUID noteId, UUID deckId);

    DeckResponse refreshStatus(UUID tenantId, UUID noteId);

    DeckResponse activate(UUID tenantId, UUID noteId, UUID deckId, UUID activatedBy);

    DeckResponse archive(UUID tenantId, UUID noteId, UUID deckId, UUID archivedBy);
}
