package com.learning.notes_service.service;

import com.learning.notes_service.exception.BadRequestException;
import com.learning.notes_service.exception.NotFoundException;
import com.learning.notes_service.model.dto.CreateDeckRequest;
import com.learning.notes_service.model.dto.DeckCompositionResponse;
import com.learning.notes_service.model.dto.DeckResponse;
import com.learning.notes_service.model.dto.UpdateDeckRequest;
import com.learning.notes_service.model.entity.Deck;
import com.learning.notes_service.model.enums.DeckStatus;
import com.learning.notes_service.repository.DeckRepository;
import com.learning.notes_service.repository.FlashcardRepository;
import com.learning.notes_service.repository.McqRepository;
import com.learning.notes_service.repository.NoteRepository;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultDeckService implements DeckService {

    private static final int DEFAULT_MCQ_COUNT = 40;
    private static final int DEFAULT_FLASHCARD_COUNT = 40;
    private static final int DEFAULT_EASY_PCT = 30;
    private static final int DEFAULT_MEDIUM_PCT = 30;
    private static final int DEFAULT_HARD_PCT = 40;

    private final DeckRepository deckRepository;
    private final NoteRepository noteRepository;
    private final McqRepository mcqRepository;
    private final FlashcardRepository flashcardRepository;

    @Override
    @Transactional
    public DeckResponse create(UUID tenantId, UUID noteId, CreateDeckRequest request) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        if (deckRepository.existsByTenantIdAndNoteId(tenantId, noteId)) {
            throw new IllegalStateException("Deck already exists for this note");
        }

        Instant now = Instant.now();
        Deck deck = new Deck();
        deck.setId(UUID.randomUUID());
        deck.setTenantId(tenantId);
        deck.setNoteId(noteId);
        deck.setTitle(request.getTitle() != null ? request.getTitle() : "Deck");
        deck.setDescription(request.getDescription());
        deck.setStatus(DeckStatus.INCOMPLETE);
        deck.setRequiredMcqCount(
                request.getRequiredMcqCount() != null ? request.getRequiredMcqCount() : DEFAULT_MCQ_COUNT);
        deck.setRequiredFlashcardCount(
                request.getRequiredFlashcardCount() != null ? request.getRequiredFlashcardCount() : DEFAULT_FLASHCARD_COUNT);
        deck.setEasyPct(request.getEasyPct() != null ? request.getEasyPct() : DEFAULT_EASY_PCT);
        deck.setMediumPct(request.getMediumPct() != null ? request.getMediumPct() : DEFAULT_MEDIUM_PCT);
        deck.setHardPct(request.getHardPct() != null ? request.getHardPct() : DEFAULT_HARD_PCT);
        deck.setCreatedBy(request.getCreatedBy());
        deck.setCreatedAt(now);
        deck.setUpdatedAt(now);
        deckRepository.save(deck);

        // Auto-validate: if composition is already met, transition to READY
        if (isCompositionMet(tenantId, noteId, deck)) {
            deck.setStatus(DeckStatus.READY);
            deck.setUpdatedAt(Instant.now());
            deckRepository.save(deck);
        }

        return toResponse(deck);
    }

    @Override
    @Transactional(readOnly = true)
    public DeckResponse getByNoteId(UUID tenantId, UUID noteId) {
        Deck deck = deckRepository.findByTenantIdAndNoteId(tenantId, noteId)
                .orElseThrow(() -> new NotFoundException("Deck not found for this note"));
        return toResponse(deck);
    }

    @Override
    @Transactional
    public DeckResponse update(UUID tenantId, UUID noteId, UUID deckId, UpdateDeckRequest request) {
        Deck deck = deckRepository.findByIdAndTenantId(deckId, tenantId)
                .orElseThrow(() -> new NotFoundException("Deck not found"));

        if (!deck.getNoteId().equals(noteId)) {
            throw new BadRequestException("Deck does not belong to this note");
        }

        boolean configChanged = false;

        if (request.getTitle() != null) {
            deck.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            deck.setDescription(request.getDescription());
        }
        if (request.getRequiredMcqCount() != null) {
            deck.setRequiredMcqCount(request.getRequiredMcqCount());
            configChanged = true;
        }
        if (request.getRequiredFlashcardCount() != null) {
            deck.setRequiredFlashcardCount(request.getRequiredFlashcardCount());
            configChanged = true;
        }
        if (request.getEasyPct() != null) {
            deck.setEasyPct(request.getEasyPct());
            configChanged = true;
        }
        if (request.getMediumPct() != null) {
            deck.setMediumPct(request.getMediumPct());
            configChanged = true;
        }
        if (request.getHardPct() != null) {
            deck.setHardPct(request.getHardPct());
            configChanged = true;
        }

        deck.setUpdatedBy(request.getUpdatedBy());
        deck.setUpdatedAt(Instant.now());

        // Re-evaluate status if composition config changed
        if (configChanged && (deck.getStatus() == DeckStatus.INCOMPLETE || deck.getStatus() == DeckStatus.READY)) {
            boolean met = isCompositionMet(tenantId, noteId, deck);
            deck.setStatus(met ? DeckStatus.READY : DeckStatus.INCOMPLETE);
        }

        deckRepository.save(deck);
        return toResponse(deck);
    }

    @Override
    @Transactional
    public void delete(UUID tenantId, UUID noteId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndTenantId(deckId, tenantId)
                .orElseThrow(() -> new NotFoundException("Deck not found"));

        if (!deck.getNoteId().equals(noteId)) {
            throw new BadRequestException("Deck does not belong to this note");
        }

        if (deck.getStatus() == DeckStatus.ACTIVE) {
            throw new IllegalStateException("Cannot delete an active deck. Archive it first.");
        }

        deckRepository.delete(deck);
    }

    @Override
    @Transactional(readOnly = true)
    public DeckCompositionResponse validateComposition(UUID tenantId, UUID noteId, UUID deckId) {
        Deck deck = deckRepository.findByIdAndTenantId(deckId, tenantId)
                .orElseThrow(() -> new NotFoundException("Deck not found"));

        if (!deck.getNoteId().equals(noteId)) {
            throw new BadRequestException("Deck does not belong to this note");
        }

        DeckCompositionResponse response = new DeckCompositionResponse();
        response.setDeckId(deckId);
        response.setNoteId(noteId);
        response.setStatus(deck.getStatus().name());

        DeckCompositionResponse.CompositionDetail mcqs = buildCompositionDetail(
                tenantId, noteId, deck.getRequiredMcqCount(),
                deck.getEasyPct(), deck.getMediumPct(), deck.getHardPct(), true);
        response.setMcqs(mcqs);

        DeckCompositionResponse.CompositionDetail flashcards = buildCompositionDetail(
                tenantId, noteId, deck.getRequiredFlashcardCount(),
                deck.getEasyPct(), deck.getMediumPct(), deck.getHardPct(), false);
        response.setFlashcards(flashcards);

        response.setCompositionMet(
                mcqs.isTotalMet() && mcqs.isEasyMet() && mcqs.isMediumMet() && mcqs.isHardMet()
                && flashcards.isTotalMet() && flashcards.isEasyMet() && flashcards.isMediumMet() && flashcards.isHardMet());

        return response;
    }

    @Override
    @Transactional
    public DeckResponse refreshStatus(UUID tenantId, UUID noteId) {
        Deck deck = deckRepository.findByTenantIdAndNoteId(tenantId, noteId).orElse(null);
        if (deck == null) {
            return null;
        }

        // Only refresh if in INCOMPLETE or READY state
        if (deck.getStatus() == DeckStatus.ACTIVE || deck.getStatus() == DeckStatus.ARCHIVED) {
            return toResponse(deck);
        }

        boolean compositionMet = isCompositionMet(tenantId, noteId, deck);

        if (compositionMet && deck.getStatus() == DeckStatus.INCOMPLETE) {
            deck.setStatus(DeckStatus.READY);
            deck.setUpdatedAt(Instant.now());
            deckRepository.save(deck);
        } else if (!compositionMet && deck.getStatus() == DeckStatus.READY) {
            deck.setStatus(DeckStatus.INCOMPLETE);
            deck.setUpdatedAt(Instant.now());
            deckRepository.save(deck);
        }

        return toResponse(deck);
    }

    @Override
    @Transactional
    public DeckResponse activate(UUID tenantId, UUID noteId, UUID deckId, UUID activatedBy) {
        Deck deck = deckRepository.findByIdAndTenantId(deckId, tenantId)
                .orElseThrow(() -> new NotFoundException("Deck not found"));

        if (!deck.getNoteId().equals(noteId)) {
            throw new BadRequestException("Deck does not belong to this note");
        }

        if (deck.getStatus() != DeckStatus.READY) {
            throw new IllegalStateException("Deck must be in READY status to activate");
        }

        deck.setStatus(DeckStatus.ACTIVE);
        deck.setUpdatedBy(activatedBy);
        deck.setUpdatedAt(Instant.now());
        deckRepository.save(deck);
        return toResponse(deck);
    }

    @Override
    @Transactional
    public DeckResponse archive(UUID tenantId, UUID noteId, UUID deckId, UUID archivedBy) {
        Deck deck = deckRepository.findByIdAndTenantId(deckId, tenantId)
                .orElseThrow(() -> new NotFoundException("Deck not found"));

        if (!deck.getNoteId().equals(noteId)) {
            throw new BadRequestException("Deck does not belong to this note");
        }

        deck.setStatus(DeckStatus.ARCHIVED);
        deck.setUpdatedBy(archivedBy);
        deck.setUpdatedAt(Instant.now());
        deckRepository.save(deck);
        return toResponse(deck);
    }

    private boolean isCompositionMet(UUID tenantId, UUID noteId, Deck deck) {
        long easyRequired = Math.round(deck.getRequiredMcqCount() * deck.getEasyPct() / 100.0);
        long mediumRequired = Math.round(deck.getRequiredMcqCount() * deck.getMediumPct() / 100.0);
        long hardRequired = deck.getRequiredMcqCount() - easyRequired - mediumRequired;

        long mcqEasy = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "LOW");
        long mcqMedium = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "MEDIUM");
        long mcqHard = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "HIGH");

        if (mcqEasy < easyRequired || mcqMedium < mediumRequired || mcqHard < hardRequired) {
            return false;
        }

        long fcEasyRequired = Math.round(deck.getRequiredFlashcardCount() * deck.getEasyPct() / 100.0);
        long fcMediumRequired = Math.round(deck.getRequiredFlashcardCount() * deck.getMediumPct() / 100.0);
        long fcHardRequired = deck.getRequiredFlashcardCount() - fcEasyRequired - fcMediumRequired;

        long fcEasy = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "LOW");
        long fcMedium = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "MEDIUM");
        long fcHard = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "HIGH");

        return fcEasy >= fcEasyRequired && fcMedium >= fcMediumRequired && fcHard >= fcHardRequired;
    }

    private DeckCompositionResponse.CompositionDetail buildCompositionDetail(
            UUID tenantId, UUID noteId, int totalRequired,
            int easyPct, int mediumPct, int hardPct, boolean isMcq) {

        long easyRequired = Math.round(totalRequired * easyPct / 100.0);
        long mediumRequired = Math.round(totalRequired * mediumPct / 100.0);
        long hardRequired = totalRequired - easyRequired - mediumRequired;

        long easyActual;
        long mediumActual;
        long hardActual;
        long totalActual;

        if (isMcq) {
            easyActual = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "LOW");
            mediumActual = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "MEDIUM");
            hardActual = mcqRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "HIGH");
            totalActual = mcqRepository.countByTenantIdAndNoteId(tenantId, noteId);
        } else {
            easyActual = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "LOW");
            mediumActual = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "MEDIUM");
            hardActual = flashcardRepository.countByTenantIdAndNoteIdAndDifficulty(tenantId, noteId, "HIGH");
            totalActual = flashcardRepository.countByTenantIdAndNoteId(tenantId, noteId);
        }

        DeckCompositionResponse.CompositionDetail detail = new DeckCompositionResponse.CompositionDetail();
        detail.setTotalRequired(totalRequired);
        detail.setTotalActual(totalActual);
        detail.setTotalMet(totalActual >= totalRequired);
        detail.setEasyRequired(easyRequired);
        detail.setEasyActual(easyActual);
        detail.setEasyMet(easyActual >= easyRequired);
        detail.setMediumRequired(mediumRequired);
        detail.setMediumActual(mediumActual);
        detail.setMediumMet(mediumActual >= mediumRequired);
        detail.setHardRequired(hardRequired);
        detail.setHardActual(hardActual);
        detail.setHardMet(hardActual >= hardRequired);
        return detail;
    }

    private DeckResponse toResponse(Deck deck) {
        DeckResponse response = new DeckResponse();
        response.setId(deck.getId());
        response.setNoteId(deck.getNoteId());
        response.setTitle(deck.getTitle());
        response.setDescription(deck.getDescription());
        response.setStatus(deck.getStatus().name());
        response.setRequiredMcqCount(deck.getRequiredMcqCount());
        response.setRequiredFlashcardCount(deck.getRequiredFlashcardCount());
        response.setEasyPct(deck.getEasyPct());
        response.setMediumPct(deck.getMediumPct());
        response.setHardPct(deck.getHardPct());
        response.setCreatedBy(deck.getCreatedBy());
        response.setUpdatedBy(deck.getUpdatedBy());
        response.setCreatedAt(deck.getCreatedAt());
        response.setUpdatedAt(deck.getUpdatedAt());
        return response;
    }
}
