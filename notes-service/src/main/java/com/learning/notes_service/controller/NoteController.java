package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.ApproveNoteRequest;
import com.learning.notes_service.model.dto.ArchiveNoteRequest;
import com.learning.notes_service.model.dto.CreateNoteRequest;
import com.learning.notes_service.model.dto.CreateNoteVersionRequest;
import com.learning.notes_service.model.dto.NoteAccessResponse;
import com.learning.notes_service.model.dto.NoteListResponse;
import com.learning.notes_service.model.dto.NoteRenderResponse;
import com.learning.notes_service.model.dto.NoteResponse;
import com.learning.notes_service.model.dto.NoteVersionListResponse;
import com.learning.notes_service.model.dto.NoteVersionResponse;
import com.learning.notes_service.model.dto.RejectNoteRequest;
import com.learning.notes_service.model.dto.ReleaseNoteRequest;
import com.learning.notes_service.model.dto.SubmitForReviewRequest;
import com.learning.notes_service.model.dto.UpdateNoteRequest;
import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import com.learning.notes_service.service.NotesService;
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
@RequestMapping("/notes")
public class NoteController {
    private final NotesService notesService;

    @PostMapping
    public ResponseEntity<NoteResponse> create(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestBody CreateNoteRequest request) {
        NoteResponse response = notesService.create(tenantId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{noteId}")
    public NoteResponse getById(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return notesService.getById(tenantId, noteId);
    }

    @GetMapping
    public NoteListResponse list(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) UUID createdBy,
            @RequestParam(required = false) NoteStatus status,
            @RequestParam(required = false) NoteScopeType scopeType,
            @RequestParam(required = false) UUID scopeId,
            @RequestParam(required = false, name = "q") String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return notesService.listNotes(tenantId, tag, createdBy, status, scopeType, scopeId, query, page, size);
    }

    @PatchMapping("/{noteId}")
    public NoteResponse update(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody UpdateNoteRequest request) {
        return notesService.update(tenantId, noteId, request);
    }

    @DeleteMapping("/{noteId}")
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        notesService.delete(tenantId, noteId);
        return ResponseEntity.noContent().build();
    }

    // ========== VERSION ENDPOINTS ==========

    @PostMapping("/{noteId}/versions")
    public ResponseEntity<NoteVersionResponse> createVersion(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody CreateNoteVersionRequest request) {
        NoteVersionResponse response = notesService.createVersion(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{noteId}/versions")
    public NoteVersionListResponse listVersions(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return notesService.listVersions(tenantId, noteId);
    }

    @GetMapping("/{noteId}/versions/{versionId}")
    public NoteVersionResponse getVersion(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID versionId) {
        return notesService.getVersion(tenantId, noteId, versionId);
    }

    // ========== WORKFLOW ENDPOINTS ==========

    /** Submit note for review: DRAFT -> IN_REVIEW */
    @PostMapping("/{noteId}/submit-for-review")
    public NoteResponse submitForReview(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody SubmitForReviewRequest request) {
        return notesService.submitForReview(tenantId, noteId, request);
    }

    /** Approve note: IN_REVIEW -> READY */
    @PostMapping("/{noteId}/approve")
    public NoteResponse approve(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody ApproveNoteRequest request) {
        return notesService.approve(tenantId, noteId, request);
    }

    /** Reject note: IN_REVIEW -> DRAFT */
    @PostMapping("/{noteId}/reject")
    public NoteResponse reject(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody RejectNoteRequest request) {
        return notesService.reject(tenantId, noteId, request);
    }

    /** Mark as ready (Teacher shortcut): DRAFT -> READY */
    @PostMapping("/{noteId}/mark-ready")
    public NoteResponse markReady(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID readyBy) {
        return notesService.markReady(tenantId, noteId, readyBy);
    }

    /** Release note to students: READY -> RELEASED */
    @PostMapping("/{noteId}/release")
    public NoteResponse release(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody ReleaseNoteRequest request) {
        return notesService.release(tenantId, noteId, request);
    }

    /** Archive note (soft delete): Any -> ARCHIVED */
    @PostMapping("/{noteId}/archive")
    public NoteResponse archive(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody ArchiveNoteRequest request) {
        return notesService.archive(tenantId, noteId, request);
    }

    // ========== OTHER ENDPOINTS ==========

    @GetMapping("/{noteId}/render")
    public NoteRenderResponse render(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return notesService.render(tenantId, noteId);
    }

    @GetMapping("/{noteId}/access")
    public NoteAccessResponse checkAccess(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID userId) {
        return notesService.checkAccess(tenantId, noteId, userId);
    }
}
