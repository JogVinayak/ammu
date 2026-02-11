package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.CreateDeckRequest;
import com.learning.notes_service.model.dto.DeckCompositionResponse;
import com.learning.notes_service.model.dto.DeckResponse;
import com.learning.notes_service.model.dto.UpdateDeckRequest;
import com.learning.notes_service.service.DeckService;
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
@RequestMapping("/notes/{noteId}/deck")
public class DeckController {

    private final DeckService deckService;

    @PostMapping
    public ResponseEntity<DeckResponse> create(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody CreateDeckRequest request) {
        DeckResponse response = deckService.create(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public DeckResponse get(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return deckService.getByNoteId(tenantId, noteId);
    }

    @PatchMapping
    public DeckResponse update(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody UpdateDeckRequest request) {
        DeckResponse existing = deckService.getByNoteId(tenantId, noteId);
        return deckService.update(tenantId, noteId, existing.getId(), request);
    }

    @DeleteMapping
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        DeckResponse existing = deckService.getByNoteId(tenantId, noteId);
        deckService.delete(tenantId, noteId, existing.getId());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/composition")
    public DeckCompositionResponse composition(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        DeckResponse existing = deckService.getByNoteId(tenantId, noteId);
        return deckService.validateComposition(tenantId, noteId, existing.getId());
    }

    @PostMapping("/refresh-status")
    public DeckResponse refreshStatus(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return deckService.refreshStatus(tenantId, noteId);
    }

    @PostMapping("/activate")
    public DeckResponse activate(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID activatedBy) {
        DeckResponse existing = deckService.getByNoteId(tenantId, noteId);
        return deckService.activate(tenantId, noteId, existing.getId(), activatedBy);
    }

    @PostMapping("/archive")
    public DeckResponse archive(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID archivedBy) {
        DeckResponse existing = deckService.getByNoteId(tenantId, noteId);
        return deckService.archive(tenantId, noteId, existing.getId(), archivedBy);
    }
}
