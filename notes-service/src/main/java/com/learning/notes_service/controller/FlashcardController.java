package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.BatchFlashcardsRequest;
import com.learning.notes_service.model.dto.CreateFlashcardRequest;
import com.learning.notes_service.model.dto.FlashcardListResponse;
import com.learning.notes_service.model.dto.FlashcardResponse;
import com.learning.notes_service.model.dto.UpdateFlashcardRequest;
import com.learning.notes_service.service.FlashcardService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/notes/{noteId}/flashcards")
public class FlashcardController {
    private final FlashcardService flashcardService;

    @PostMapping
    public ResponseEntity<FlashcardResponse> create(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody CreateFlashcardRequest request) {
        FlashcardResponse response = flashcardService.create(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public FlashcardListResponse list(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam(required = false) String difficulty) {
        if (difficulty != null && !difficulty.isEmpty()) {
            return flashcardService.listByNoteAndDifficulty(tenantId, noteId, difficulty);
        }
        return flashcardService.listByNote(tenantId, noteId);
    }

    @GetMapping("/{flashcardId}")
    public FlashcardResponse getById(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID flashcardId) {
        return flashcardService.getById(tenantId, noteId, flashcardId);
    }

    @PatchMapping("/{flashcardId}")
    public FlashcardResponse update(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID flashcardId,
            @RequestBody UpdateFlashcardRequest request) {
        return flashcardService.update(tenantId, noteId, flashcardId, request);
    }

    @DeleteMapping("/{flashcardId}")
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID flashcardId) {
        flashcardService.delete(tenantId, noteId, flashcardId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/batch")
    public FlashcardListResponse batchUpsert(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody BatchFlashcardsRequest request) {
        return flashcardService.batchUpsert(tenantId, noteId, request);
    }
}
