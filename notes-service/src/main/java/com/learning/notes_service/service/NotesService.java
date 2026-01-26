package com.learning.notes_service.service;

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
import java.util.UUID;

public interface NotesService {
    NoteResponse create(UUID tenantId, CreateNoteRequest request);

    NoteResponse getById(UUID tenantId, UUID noteId);

    NoteListResponse listNotes(
            UUID tenantId,
            String tag,
            UUID createdBy,
            NoteStatus status,
            NoteScopeType scopeType,
            UUID scopeId,
            String query,
            int page,
            int size);

    NoteResponse update(UUID tenantId, UUID noteId, UpdateNoteRequest request);

    void delete(UUID tenantId, UUID noteId);

    NoteVersionResponse createVersion(UUID tenantId, UUID noteId, CreateNoteVersionRequest request);

    NoteVersionListResponse listVersions(UUID tenantId, UUID noteId);

    NoteVersionResponse getVersion(UUID tenantId, UUID noteId, UUID versionId);

    NoteRenderResponse render(UUID tenantId, UUID noteId);

    NoteAccessResponse checkAccess(UUID tenantId, UUID noteId, UUID userId);

    // Workflow methods
    
    /** Submit note for review: DRAFT -> IN_REVIEW */
    NoteResponse submitForReview(UUID tenantId, UUID noteId, SubmitForReviewRequest request);

    /** Approve note: IN_REVIEW -> READY (Admin/Principal action) */
    NoteResponse approve(UUID tenantId, UUID noteId, ApproveNoteRequest request);

    /** Reject note: IN_REVIEW -> DRAFT (with feedback) */
    NoteResponse reject(UUID tenantId, UUID noteId, RejectNoteRequest request);

    /** Mark as ready (Teacher shortcut): DRAFT -> READY (skips review) */
    NoteResponse markReady(UUID tenantId, UUID noteId, UUID readyBy);

    /** Release note to students: READY -> RELEASED */
    NoteResponse release(UUID tenantId, UUID noteId, ReleaseNoteRequest request);

    /** Archive note (soft delete): Any -> ARCHIVED */
    NoteResponse archive(UUID tenantId, UUID noteId, ArchiveNoteRequest request);
}
