package com.learning.notes_service.controller;

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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/notes")
public class NoteController {
    private final NotesService notesService;

    @PostMapping
    public ResponseEntity<NoteResponse> create(@RequestBody CreateNoteRequest request) {
        NoteResponse response = notesService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{noteId}")
    public NoteResponse getById(@PathVariable UUID noteId) {
        return notesService.getById(noteId);
    }

    @GetMapping
    public NoteListResponse list(
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) UUID createdBy,
            @RequestParam(required = false) NoteStatus status,
            @RequestParam(required = false) NoteScopeType scopeType,
            @RequestParam(required = false) UUID scopeId,
            @RequestParam(required = false, name = "q") String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return notesService.listNotes(tag, createdBy, status, scopeType, scopeId, query, page, size);
    }

    @PatchMapping("/{noteId}")
    public NoteResponse update(@PathVariable UUID noteId, @RequestBody UpdateNoteRequest request) {
        return notesService.update(noteId, request);
    }

    @DeleteMapping("/{noteId}")
    public ResponseEntity<Void> delete(@PathVariable UUID noteId) {
        notesService.delete(noteId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{noteId}/versions")
    public ResponseEntity<NoteVersionResponse> createVersion(
            @PathVariable UUID noteId, @RequestBody CreateNoteVersionRequest request) {
        NoteVersionResponse response = notesService.createVersion(noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{noteId}/versions")
    public NoteVersionListResponse listVersions(@PathVariable UUID noteId) {
        return notesService.listVersions(noteId);
    }

    @GetMapping("/{noteId}/versions/{versionId}")
    public NoteVersionResponse getVersion(@PathVariable UUID noteId, @PathVariable UUID versionId) {
        return notesService.getVersion(noteId, versionId);
    }

    @PostMapping("/{noteId}/publish")
    public NoteResponse publish(@PathVariable UUID noteId, @RequestBody PublishNoteRequest request) {
        return notesService.publish(noteId, request);
    }

    @GetMapping("/{noteId}/render")
    public NoteRenderResponse render(@PathVariable UUID noteId) {
        return notesService.render(noteId);
    }

    @GetMapping("/{noteId}/access")
    public NoteAccessResponse checkAccess(
            @PathVariable UUID noteId, @RequestParam UUID userId) {
        return notesService.checkAccess(noteId, userId);
    }
}
