package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.BatchFlashcardsRequest;
import com.learning.notes_service.model.dto.CreateFlashcardRequest;
import com.learning.notes_service.model.dto.FlashcardListResponse;
import com.learning.notes_service.model.dto.FlashcardResponse;
import com.learning.notes_service.model.dto.UpdateFlashcardRequest;
import java.util.UUID;

public interface FlashcardService {

    FlashcardResponse create(UUID tenantId, UUID noteId, CreateFlashcardRequest request);

    FlashcardListResponse listByNote(UUID tenantId, UUID noteId);

    FlashcardListResponse listByNoteAndDifficulty(UUID tenantId, UUID noteId, String difficulty);

    FlashcardResponse getById(UUID tenantId, UUID noteId, UUID flashcardId);

    FlashcardResponse update(UUID tenantId, UUID noteId, UUID flashcardId, UpdateFlashcardRequest request);

    void delete(UUID tenantId, UUID noteId, UUID flashcardId);

    FlashcardListResponse batchUpsert(UUID tenantId, UUID noteId, BatchFlashcardsRequest request);
}
