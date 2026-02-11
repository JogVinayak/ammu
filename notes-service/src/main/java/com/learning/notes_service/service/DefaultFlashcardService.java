package com.learning.notes_service.service;

import com.learning.notes_service.exception.BadRequestException;
import com.learning.notes_service.exception.NotFoundException;
import com.learning.notes_service.model.dto.BatchFlashcardsRequest;
import com.learning.notes_service.model.dto.CreateFlashcardRequest;
import com.learning.notes_service.model.dto.FlashcardListResponse;
import com.learning.notes_service.model.dto.FlashcardResponse;
import com.learning.notes_service.model.dto.UpdateFlashcardRequest;
import com.learning.notes_service.model.entity.Flashcard;
import com.learning.notes_service.repository.DeckRepository;
import com.learning.notes_service.repository.FlashcardRepository;
import com.learning.notes_service.repository.NoteRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultFlashcardService implements FlashcardService {

    private final FlashcardRepository flashcardRepository;
    private final NoteRepository noteRepository;
    private final DeckRepository deckRepository;
    private final DeckService deckService;

    @Override
    @Transactional
    public FlashcardResponse create(UUID tenantId, UUID noteId, CreateFlashcardRequest request) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        Instant now = Instant.now();
        Integer position = request.getPosition();
        if (position == null) {
            position = flashcardRepository.findMaxPosition(tenantId, noteId) + 1;
        }

        Flashcard flashcard = new Flashcard();
        flashcard.setId(UUID.randomUUID());
        flashcard.setTenantId(tenantId);
        flashcard.setNoteId(noteId);
        flashcard.setFrontText(request.getFrontText());
        flashcard.setBackText(request.getBackText());
        flashcard.setDifficulty(request.getDifficulty() != null ? request.getDifficulty() : "MEDIUM");
        flashcard.setPosition(position);
        flashcard.setCreatedBy(request.getCreatedBy());
        flashcard.setCreatedAt(now);
        flashcard.setUpdatedAt(now);

        flashcardRepository.save(flashcard);
        refreshDeckIfExists(tenantId, noteId);
        return toResponse(flashcard);
    }

    @Override
    @Transactional(readOnly = true)
    public FlashcardListResponse listByNote(UUID tenantId, UUID noteId) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        List<Flashcard> flashcards = flashcardRepository
                .findByTenantIdAndNoteIdOrderByPositionAsc(tenantId, noteId);

        FlashcardListResponse response = new FlashcardListResponse();
        response.setNoteId(noteId);
        response.setItems(flashcards.stream().map(this::toResponse).collect(Collectors.toList()));
        response.setTotal(flashcards.size());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public FlashcardListResponse listByNoteAndDifficulty(UUID tenantId, UUID noteId, String difficulty) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        List<Flashcard> flashcards = flashcardRepository
                .findByTenantIdAndNoteIdAndDifficultyOrderByPositionAsc(tenantId, noteId, difficulty);

        FlashcardListResponse response = new FlashcardListResponse();
        response.setNoteId(noteId);
        response.setItems(flashcards.stream().map(this::toResponse).collect(Collectors.toList()));
        response.setTotal(flashcards.size());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public FlashcardResponse getById(UUID tenantId, UUID noteId, UUID flashcardId) {
        Flashcard flashcard = flashcardRepository.findByIdAndTenantId(flashcardId, tenantId)
                .orElseThrow(() -> new NotFoundException("Flashcard not found"));

        if (!flashcard.getNoteId().equals(noteId)) {
            throw new BadRequestException("Flashcard does not belong to this note");
        }

        return toResponse(flashcard);
    }

    @Override
    @Transactional
    public FlashcardResponse update(UUID tenantId, UUID noteId, UUID flashcardId,
                                     UpdateFlashcardRequest request) {
        Flashcard flashcard = flashcardRepository.findByIdAndTenantId(flashcardId, tenantId)
                .orElseThrow(() -> new NotFoundException("Flashcard not found"));

        if (!flashcard.getNoteId().equals(noteId)) {
            throw new BadRequestException("Flashcard does not belong to this note");
        }

        if (request.getFrontText() != null) {
            flashcard.setFrontText(request.getFrontText());
        }
        if (request.getBackText() != null) {
            flashcard.setBackText(request.getBackText());
        }
        if (request.getDifficulty() != null) {
            flashcard.setDifficulty(request.getDifficulty());
        }
        if (request.getPosition() != null) {
            flashcard.setPosition(request.getPosition());
        }
        flashcard.setUpdatedAt(Instant.now());

        flashcardRepository.save(flashcard);
        return toResponse(flashcard);
    }

    @Override
    @Transactional
    public void delete(UUID tenantId, UUID noteId, UUID flashcardId) {
        Flashcard flashcard = flashcardRepository.findByIdAndTenantId(flashcardId, tenantId)
                .orElseThrow(() -> new NotFoundException("Flashcard not found"));

        if (!flashcard.getNoteId().equals(noteId)) {
            throw new BadRequestException("Flashcard does not belong to this note");
        }

        flashcardRepository.delete(flashcard);
        refreshDeckIfExists(tenantId, noteId);
    }

    @Override
    @Transactional
    public FlashcardListResponse batchUpsert(UUID tenantId, UUID noteId,
                                              BatchFlashcardsRequest request) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        Instant now = Instant.now();

        if (request.isReplaceAll()) {
            flashcardRepository.deleteByTenantIdAndNoteId(tenantId, noteId);
        }

        for (int i = 0; i < request.getFlashcards().size(); i++) {
            BatchFlashcardsRequest.FlashcardItem item = request.getFlashcards().get(i);

            Flashcard flashcard;
            if (item.getId() != null && !request.isReplaceAll()) {
                flashcard = flashcardRepository.findByIdAndTenantId(item.getId(), tenantId)
                        .orElse(new Flashcard());
                if (flashcard.getId() == null) {
                    flashcard.setId(UUID.randomUUID());
                    flashcard.setCreatedAt(now);
                    flashcard.setCreatedBy(request.getCreatedBy());
                }
            } else {
                flashcard = new Flashcard();
                flashcard.setId(UUID.randomUUID());
                flashcard.setCreatedAt(now);
                flashcard.setCreatedBy(request.getCreatedBy());
            }

            flashcard.setTenantId(tenantId);
            flashcard.setNoteId(noteId);
            flashcard.setFrontText(item.getFrontText());
            flashcard.setBackText(item.getBackText());
            flashcard.setDifficulty(item.getDifficulty() != null ? item.getDifficulty() : "MEDIUM");
            flashcard.setPosition(item.getPosition() != null ? item.getPosition() : i + 1);
            flashcard.setUpdatedAt(now);

            flashcardRepository.save(flashcard);
        }

        refreshDeckIfExists(tenantId, noteId);
        return listByNote(tenantId, noteId);
    }

    private void refreshDeckIfExists(UUID tenantId, UUID noteId) {
        if (deckRepository.existsByTenantIdAndNoteId(tenantId, noteId)) {
            deckService.refreshStatus(tenantId, noteId);
        }
    }

    private FlashcardResponse toResponse(Flashcard flashcard) {
        FlashcardResponse response = new FlashcardResponse();
        response.setId(flashcard.getId());
        response.setNoteId(flashcard.getNoteId());
        response.setFrontText(flashcard.getFrontText());
        response.setBackText(flashcard.getBackText());
        response.setDifficulty(flashcard.getDifficulty());
        response.setPosition(flashcard.getPosition());
        response.setCreatedBy(flashcard.getCreatedBy());
        response.setCreatedAt(flashcard.getCreatedAt());
        response.setUpdatedAt(flashcard.getUpdatedAt());
        return response;
    }
}
