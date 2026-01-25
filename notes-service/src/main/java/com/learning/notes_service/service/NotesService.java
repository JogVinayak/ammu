package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.CreateNoteRequest;
import com.learning.notes_service.model.dto.CreateNoteVersionRequest;
import com.learning.notes_service.model.dto.NoteAccessResponse;
import com.learning.notes_service.model.dto.NoteListResponse;
import com.learning.notes_service.model.dto.NoteRenderResponse;
import com.learning.notes_service.model.dto.NoteResponse;
import com.learning.notes_service.model.dto.NoteVersionListResponse;
import com.learning.notes_service.model.dto.NoteVersionResponse;
import com.learning.notes_service.model.dto.PublishNoteRequest;
import com.learning.notes_service.model.dto.UpdateNoteRequest;
import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import java.util.UUID;

public interface NotesService {
    NoteResponse create(CreateNoteRequest request);

    NoteResponse getById(UUID noteId);

    NoteListResponse listNotes(
            String tag,
            UUID createdBy,
            NoteStatus status,
            NoteScopeType scopeType,
            UUID scopeId,
            String query,
            int page,
            int size);

    NoteResponse update(UUID noteId, UpdateNoteRequest request);

    void delete(UUID noteId);

    NoteVersionResponse createVersion(UUID noteId, CreateNoteVersionRequest request);

    NoteVersionListResponse listVersions(UUID noteId);

    NoteVersionResponse getVersion(UUID noteId, UUID versionId);

    NoteResponse publish(UUID noteId, PublishNoteRequest request);

    NoteRenderResponse render(UUID noteId);

    NoteAccessResponse checkAccess(UUID noteId, UUID userId);
}
