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
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class DefaultNotesService implements NotesService {
    private static final int DEFAULT_PAGE_SIZE = 20;

    @Override
    public NoteResponse create(CreateNoteRequest request) {
        UUID noteId = UUID.randomUUID();
        UUID tenantId = resolveOrRandom(request.getTenantId());
        UUID createdBy = resolveOrRandom(request.getCreatedBy());
        Instant now = Instant.now();
        UUID versionId = UUID.randomUUID();

        NoteResponse response = buildNoteResponse(
                noteId,
                tenantId,
                request.getTitle(),
                request.getSummary(),
                NoteStatus.DRAFT,
                normalizeTags(request.getTags()),
                request.getScopeType(),
                request.getScopeId(),
                createdBy,
                createdBy,
                now,
                now);
        response.setLatestVersionId(versionId);
        return response;
    }

    @Override
    public NoteResponse getById(UUID noteId) {
        UUID tenantId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Instant now = Instant.now();
        NoteResponse response = buildNoteResponse(
                noteId,
                tenantId,
                "Sample Note",
                "Sample summary",
                NoteStatus.DRAFT,
                List.of("sample"),
                NoteScopeType.TENANT,
                null,
                userId,
                userId,
                now,
                now);
        response.setLatestVersionId(UUID.randomUUID());
        return response;
    }

    @Override
    public NoteListResponse listNotes(
            String tag,
            UUID createdBy,
            NoteStatus status,
            NoteScopeType scopeType,
            UUID scopeId,
            String query,
            int page,
            int size) {
        NoteResponse sample = buildNoteResponse(
                UUID.randomUUID(),
                UUID.randomUUID(),
                query == null || query.isBlank() ? "Notes Sample" : "Notes for " + query,
                "Sample summary",
                status == null ? NoteStatus.DRAFT : status,
                normalizeTags(tag == null ? null : List.of(tag)),
                scopeType,
                scopeId,
                createdBy == null ? UUID.randomUUID() : createdBy,
                UUID.randomUUID(),
                Instant.now(),
                Instant.now());
        sample.setLatestVersionId(UUID.randomUUID());

        NoteListResponse response = new NoteListResponse();
        response.setItems(List.of(sample));
        response.setPage(Math.max(page, 0));
        response.setSize(size > 0 ? size : DEFAULT_PAGE_SIZE);
        response.setTotal(1);
        return response;
    }

    @Override
    public NoteResponse update(UUID noteId, UpdateNoteRequest request) {
        UUID tenantId = UUID.randomUUID();
        UUID updatedBy = resolveOrRandom(request.getUpdatedBy());
        Instant now = Instant.now();
        NoteResponse response = buildNoteResponse(
                noteId,
                tenantId,
                request.getTitle() == null ? "Updated Note" : request.getTitle(),
                request.getSummary(),
                request.getStatus() == null ? NoteStatus.DRAFT : request.getStatus(),
                normalizeTags(request.getTags()),
                request.getScopeType(),
                request.getScopeId(),
                updatedBy,
                updatedBy,
                now,
                now);
        response.setLatestVersionId(UUID.randomUUID());
        return response;
    }

    @Override
    public void delete(UUID noteId) {
    }

    @Override
    public NoteVersionResponse createVersion(UUID noteId, CreateNoteVersionRequest request) {
        NoteVersionResponse response = buildVersionResponse(
                noteId,
                UUID.randomUUID(),
                2,
                resolveOrRandom(request.getCreatedBy()),
                request.getContentMd(),
                request.getContentHash(),
                request.getChangeSummary());
        return response;
    }

    @Override
    public NoteVersionListResponse listVersions(UUID noteId) {
        NoteVersionResponse response = buildVersionResponse(
                noteId,
                UUID.randomUUID(),
                1,
                UUID.randomUUID(),
                "## Sample Note\n\nThis is a sample version.",
                null,
                "Initial draft");
        NoteVersionListResponse listResponse = new NoteVersionListResponse();
        listResponse.setNoteId(noteId);
        listResponse.setItems(List.of(response));
        return listResponse;
    }

    @Override
    public NoteVersionResponse getVersion(UUID noteId, UUID versionId) {
        return buildVersionResponse(
                noteId,
                versionId,
                1,
                UUID.randomUUID(),
                "## Sample Note\n\nThis is a sample version.",
                null,
                "Initial draft");
    }

    @Override
    public NoteResponse publish(UUID noteId, PublishNoteRequest request) {
        UUID tenantId = UUID.randomUUID();
        UUID publishedBy = resolveOrRandom(request.getPublishedBy());
        Instant now = Instant.now();
        UUID versionId = request.getVersionId() == null ? UUID.randomUUID() : request.getVersionId();

        NoteResponse response = buildNoteResponse(
                noteId,
                tenantId,
                "Published Note",
                "Published summary",
                NoteStatus.PUBLISHED,
                List.of("published"),
                NoteScopeType.TENANT,
                null,
                publishedBy,
                publishedBy,
                now,
                now);
        response.setPublishedAt(now);
        response.setLatestVersionId(versionId);
        response.setLatestPublishedVersionId(versionId);
        return response;
    }

    @Override
    public NoteRenderResponse render(UUID noteId) {
        NoteRenderResponse response = new NoteRenderResponse();
        response.setNoteId(noteId);
        response.setVersionId(UUID.randomUUID());
        response.setVersionNo(1);
        response.setTitle("Rendered Note");
        response.setContentMd("## Rendered Note\n\n$E=mc^2$");
        response.setPublishedAt(Instant.now());
        response.setStatus(NoteStatus.PUBLISHED);
        return response;
    }

    @Override
    public NoteAccessResponse checkAccess(UUID noteId, UUID userId) {
        NoteAccessResponse response = new NoteAccessResponse();
        response.setCanRead(true);
        response.setCanWrite(false);
        return response;
    }

    private NoteResponse buildNoteResponse(
            UUID noteId,
            UUID tenantId,
            String title,
            String summary,
            NoteStatus status,
            List<String> tags,
            NoteScopeType scopeType,
            UUID scopeId,
            UUID createdBy,
            UUID updatedBy,
            Instant createdAt,
            Instant updatedAt) {
        NoteResponse response = new NoteResponse();
        response.setId(noteId);
        response.setTenantId(tenantId);
        response.setTitle(title == null ? "Untitled Note" : title);
        response.setSummary(summary);
        response.setStatus(status == null ? NoteStatus.DRAFT : status);
        response.setCreatedBy(createdBy);
        response.setUpdatedBy(updatedBy);
        response.setCreatedAt(createdAt);
        response.setUpdatedAt(updatedAt);
        response.setDeleted(false);
        response.setTags(tags == null ? List.of() : tags);
        response.setScopeType(scopeType);
        response.setScopeId(scopeId);
        return response;
    }

    private NoteVersionResponse buildVersionResponse(
            UUID noteId,
            UUID versionId,
            int versionNo,
            UUID createdBy,
            String contentMd,
            String contentHash,
            String changeSummary) {
        NoteVersionResponse response = new NoteVersionResponse();
        response.setId(versionId);
        response.setTenantId(UUID.randomUUID());
        response.setNoteId(noteId);
        response.setVersionNo(versionNo);
        response.setContentMd(contentMd == null ? "" : contentMd);
        response.setContentHash(contentHash);
        response.setChangeSummary(changeSummary);
        response.setCreatedBy(createdBy);
        response.setCreatedAt(Instant.now());
        return response;
    }

    private UUID resolveOrRandom(UUID value) {
        return value == null ? UUID.randomUUID() : value;
    }

    private List<String> normalizeTags(List<String> tags) {
        if (tags == null) {
            return List.of();
        }
        return tags.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .collect(Collectors.toList());
    }
}
