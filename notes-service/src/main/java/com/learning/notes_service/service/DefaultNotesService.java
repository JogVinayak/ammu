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
import com.learning.notes_service.model.entity.Note;
import com.learning.notes_service.model.entity.NoteTag;
import com.learning.notes_service.model.entity.NoteVersion;
import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import com.learning.notes_service.repository.NoteRepository;
import com.learning.notes_service.repository.NoteTagRepository;
import com.learning.notes_service.repository.NoteVersionRepository;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultNotesService implements NotesService {

    private final NoteRepository noteRepository;
    private final NoteVersionRepository versionRepository;
    private final NoteTagRepository tagRepository;
    private final GuidedReadingParser guidedReadingParser;

    @Override
    @Transactional
    public NoteResponse create(UUID tenantId, CreateNoteRequest request) {
        Instant now = Instant.now();
        UUID noteId = UUID.randomUUID();
        UUID versionId = UUID.randomUUID();

        Note note = new Note();
        note.setId(noteId);
        note.setTenantId(tenantId);
        note.setTitle(request.getTitle() != null ? request.getTitle() : "Untitled Note");
        note.setSummary(request.getSummary());
        note.setStatus(NoteStatus.DRAFT);
        note.setCreatedBy(request.getCreatedBy());
        note.setUpdatedBy(request.getCreatedBy());
        note.setCreatedAt(now);
        note.setUpdatedAt(now);
        note.setScopeType(request.getScopeType());
        note.setScopeId(request.getScopeId());
        note.setDeleted(false);
        note.setLatestVersionId(versionId);

        noteRepository.save(note);

        if (request.getContentMd() != null && !request.getContentMd().isBlank()) {
            NoteVersion version = new NoteVersion();
            version.setId(versionId);
            version.setTenantId(tenantId);
            version.setNoteId(noteId);
            version.setVersionNo(1);
            version.setContentMd(request.getContentMd());
            version.setContentGuidedJson(guidedReadingParser.parse(request.getContentMd()));
            version.setChangeSummary(request.getChangeSummary());
            version.setCreatedBy(request.getCreatedBy());
            version.setCreatedAt(now);
            versionRepository.save(version);
        }

        saveTags(tenantId, noteId, request.getTags());
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional(readOnly = true)
    public NoteResponse getById(UUID tenantId, UUID noteId) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional(readOnly = true)
    public NoteListResponse listNotes(
            UUID tenantId,
            String tag,
            UUID createdBy,
            NoteStatus status,
            NoteScopeType scopeType,
            UUID scopeId,
            String query,
            int page,
            int size) {

        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                size > 0 ? size : 20,
                Sort.by(Sort.Direction.DESC, "updatedAt"));

        Page<Note> notesPage;

        if (status != null) {
            notesPage = noteRepository.findByTenantIdAndStatusAndDeletedFalse(tenantId, status, pageable);
        } else if (createdBy != null) {
            notesPage = noteRepository.findByTenantIdAndCreatedByAndDeletedFalse(tenantId, createdBy, pageable);
        } else if (scopeType != null && scopeId != null) {
            notesPage = noteRepository.findByTenantIdAndScopeTypeAndScopeIdAndDeletedFalse(
                    tenantId, scopeType, scopeId, pageable);
        } else if (scopeType != null) {
            notesPage = noteRepository.findByTenantIdAndScopeTypeAndDeletedFalse(tenantId, scopeType, pageable);
        } else {
            // Default: return only RELEASED notes (students should not see drafts)
            notesPage = noteRepository.findByTenantIdAndStatusAndDeletedFalse(
                    tenantId, NoteStatus.RELEASED, pageable);
        }

        List<NoteResponse> items = notesPage.getContent().stream()
                .map(note -> toNoteResponse(note, getTags(tenantId, note.getId())))
                .collect(Collectors.toList());

        NoteListResponse response = new NoteListResponse();
        response.setItems(items);
        response.setPage(notesPage.getNumber());
        response.setSize(notesPage.getSize());
        response.setTotal(notesPage.getTotalElements());
        return response;
    }

    @Override
    @Transactional
    public NoteResponse update(UUID tenantId, UUID noteId, UpdateNoteRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        Instant now = Instant.now();

        if (request.getTitle() != null) {
            note.setTitle(request.getTitle());
        }
        if (request.getSummary() != null) {
            note.setSummary(request.getSummary());
        }
        if (request.getStatus() != null) {
            note.setStatus(request.getStatus());
        }
        if (request.getScopeType() != null) {
            note.setScopeType(request.getScopeType());
        }
        if (request.getScopeId() != null) {
            note.setScopeId(request.getScopeId());
        }
        if (request.getUpdatedBy() != null) {
            note.setUpdatedBy(request.getUpdatedBy());
        }
        note.setUpdatedAt(now);

        if (request.getTags() != null) {
            tagRepository.deleteByTenantIdAndNoteId(tenantId, noteId);
            saveTags(tenantId, noteId, request.getTags());
        }

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public void delete(UUID tenantId, UUID noteId) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .ifPresent(note -> {
                    note.setDeleted(true);
                    note.setUpdatedAt(Instant.now());
                    noteRepository.save(note);
                });
    }

    @Override
    @Transactional
    public NoteVersionResponse createVersion(UUID tenantId, UUID noteId, CreateNoteVersionRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        Integer maxVersion = versionRepository.findMaxVersionNo(tenantId, noteId);
        int newVersionNo = maxVersion + 1;
        UUID versionId = UUID.randomUUID();
        Instant now = Instant.now();

        String contentMd = request.getContentMd() != null ? request.getContentMd() : "";

        NoteVersion version = new NoteVersion();
        version.setId(versionId);
        version.setTenantId(tenantId);
        version.setNoteId(noteId);
        version.setVersionNo(newVersionNo);
        version.setContentMd(contentMd);
        version.setContentGuidedJson(guidedReadingParser.parse(contentMd));
        version.setContentHash(request.getContentHash());
        version.setChangeSummary(request.getChangeSummary());
        version.setCreatedBy(request.getCreatedBy());
        version.setCreatedAt(now);

        versionRepository.save(version);

        note.setLatestVersionId(versionId);
        note.setUpdatedAt(now);
        noteRepository.save(note);

        return toVersionResponse(version);
    }

    @Override
    @Transactional(readOnly = true)
    public NoteVersionListResponse listVersions(UUID tenantId, UUID noteId) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        List<NoteVersion> versions = versionRepository.findByTenantIdAndNoteIdOrderByVersionNoDesc(tenantId, noteId);

        NoteVersionListResponse response = new NoteVersionListResponse();
        response.setNoteId(noteId);
        response.setItems(versions.stream().map(this::toVersionResponse).collect(Collectors.toList()));
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public NoteVersionResponse getVersion(UUID tenantId, UUID noteId, UUID versionId) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        NoteVersion version = versionRepository.findByIdAndTenantId(versionId, tenantId)
                .orElseThrow(() -> new RuntimeException("Version not found"));

        if (!version.getNoteId().equals(noteId)) {
            throw new RuntimeException("Version does not belong to this note");
        }

        return toVersionResponse(version);
    }

    @Override
    @Transactional(readOnly = true)
    public NoteRenderResponse render(UUID tenantId, UUID noteId) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        NoteVersion version = null;
        if (note.getLatestReleasedVersionId() != null) {
            version = versionRepository.findByIdAndTenantId(note.getLatestReleasedVersionId(), tenantId)
                    .orElse(null);
        }
        if (version == null && note.getLatestVersionId() != null) {
            version = versionRepository.findByIdAndTenantId(note.getLatestVersionId(), tenantId)
                    .orElse(null);
        }

        NoteRenderResponse response = new NoteRenderResponse();
        response.setNoteId(noteId);
        response.setTitle(note.getTitle());
        response.setStatus(note.getStatus());
        response.setPublishedAt(note.getReleasedAt());

        if (version != null) {
            response.setVersionId(version.getId());
            response.setVersionNo(version.getVersionNo());
            response.setContentMd(version.getContentMd());
            response.setContentGuidedJson(version.getContentGuidedJson());
        }

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public NoteAccessResponse checkAccess(UUID tenantId, UUID noteId, UUID userId) {
        NoteAccessResponse response = new NoteAccessResponse();

        try {
            Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                    .orElse(null);

            if (note == null) {
                response.setCanRead(false);
                response.setCanWrite(false);
                return response;
            }

            response.setCanRead(true);
            response.setCanWrite(note.getCreatedBy() != null && note.getCreatedBy().equals(userId));
        } catch (Exception e) {
            response.setCanRead(false);
            response.setCanWrite(false);
        }

        return response;
    }

    // ========== WORKFLOW METHODS ==========

    @Override
    @Transactional
    public NoteResponse submitForReview(UUID tenantId, UUID noteId, SubmitForReviewRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        if (note.getStatus() != NoteStatus.DRAFT) {
            throw new RuntimeException("Only DRAFT notes can be submitted for review");
        }

        Instant now = Instant.now();
        note.setStatus(NoteStatus.IN_REVIEW);
        note.setSubmittedAt(now);
        note.setSubmittedBy(request.getSubmittedBy());
        note.setUpdatedAt(now);
        note.setRejectionReason(null); // Clear any previous rejection

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public NoteResponse approve(UUID tenantId, UUID noteId, ApproveNoteRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        if (note.getStatus() != NoteStatus.IN_REVIEW) {
            throw new RuntimeException("Only IN_REVIEW notes can be approved");
        }

        Instant now = Instant.now();
        note.setStatus(NoteStatus.READY);
        note.setReviewedAt(now);
        note.setReviewedBy(request.getApprovedBy());
        note.setUpdatedAt(now);

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public NoteResponse reject(UUID tenantId, UUID noteId, RejectNoteRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        if (note.getStatus() != NoteStatus.IN_REVIEW) {
            throw new RuntimeException("Only IN_REVIEW notes can be rejected");
        }

        Instant now = Instant.now();
        note.setStatus(NoteStatus.DRAFT); // Back to draft for revision
        note.setReviewedAt(now);
        note.setReviewedBy(request.getRejectedBy());
        note.setRejectionReason(request.getRejectionReason());
        note.setUpdatedAt(now);

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public NoteResponse markReady(UUID tenantId, UUID noteId, UUID readyBy) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        if (note.getStatus() != NoteStatus.DRAFT) {
            throw new RuntimeException("Only DRAFT notes can be marked as ready");
        }

        Instant now = Instant.now();
        note.setStatus(NoteStatus.READY);
        note.setReviewedAt(now);
        note.setReviewedBy(readyBy);
        note.setUpdatedAt(now);

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public NoteResponse release(UUID tenantId, UUID noteId, ReleaseNoteRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        if (note.getStatus() != NoteStatus.READY) {
            throw new RuntimeException("Only READY notes can be released");
        }

        Instant now = Instant.now();
        UUID versionId = request.getVersionId() != null ? request.getVersionId() : note.getLatestVersionId();

        if (versionId != null) {
            versionRepository.findByIdAndTenantId(versionId, tenantId)
                    .orElseThrow(() -> new RuntimeException("Version not found"));
        }

        note.setStatus(NoteStatus.RELEASED);
        note.setReleasedAt(now);
        note.setReleasedBy(request.getReleasedBy());
        note.setLatestReleasedVersionId(versionId);
        note.setUpdatedAt(now);

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    @Override
    @Transactional
    public NoteResponse archive(UUID tenantId, UUID noteId, ArchiveNoteRequest request) {
        Note note = noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        Instant now = Instant.now();
        note.setStatus(NoteStatus.ARCHIVED);
        note.setArchivedAt(now);
        note.setArchivedBy(request.getArchivedBy());
        note.setArchiveReason(request.getArchiveReason());
        note.setUpdatedAt(now);

        noteRepository.save(note);
        return toNoteResponse(note, getTags(tenantId, noteId));
    }

    // ========== HELPER METHODS ==========

    private void saveTags(UUID tenantId, UUID noteId, List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return;
        }

        Instant now = Instant.now();
        List<String> normalizedTags = tags.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(t -> !t.isEmpty())
                .distinct()
                .collect(Collectors.toList());

        for (String tag : normalizedTags) {
            if (!tagRepository.existsByTenantIdAndNoteIdAndTag(tenantId, noteId, tag)) {
                NoteTag noteTag = new NoteTag();
                noteTag.setId(UUID.randomUUID());
                noteTag.setTenantId(tenantId);
                noteTag.setNoteId(noteId);
                noteTag.setTag(tag);
                noteTag.setCreatedAt(now);
                tagRepository.save(noteTag);
            }
        }
    }

    private List<String> getTags(UUID tenantId, UUID noteId) {
        return tagRepository.findByTenantIdAndNoteId(tenantId, noteId).stream()
                .map(NoteTag::getTag)
                .collect(Collectors.toList());
    }

    private NoteResponse toNoteResponse(Note note, List<String> tags) {
        NoteResponse response = new NoteResponse();
        response.setId(note.getId());
        response.setTenantId(note.getTenantId());
        response.setTitle(note.getTitle());
        response.setSummary(note.getSummary());
        response.setStatus(note.getStatus());
        response.setCreatedBy(note.getCreatedBy());
        response.setUpdatedBy(note.getUpdatedBy());
        response.setCreatedAt(note.getCreatedAt());
        response.setUpdatedAt(note.getUpdatedAt());
        response.setSubmittedAt(note.getSubmittedAt());
        response.setSubmittedBy(note.getSubmittedBy());
        response.setReviewedAt(note.getReviewedAt());
        response.setReviewedBy(note.getReviewedBy());
        response.setRejectionReason(note.getRejectionReason());
        response.setReleasedAt(note.getReleasedAt());
        response.setReleasedBy(note.getReleasedBy());
        response.setLatestVersionId(note.getLatestVersionId());
        response.setLatestReleasedVersionId(note.getLatestReleasedVersionId());
        response.setArchivedAt(note.getArchivedAt());
        response.setArchivedBy(note.getArchivedBy());
        response.setArchiveReason(note.getArchiveReason());
        response.setScopeType(note.getScopeType());
        response.setScopeId(note.getScopeId());
        response.setDeleted(note.isDeleted());
        response.setTags(tags);
        return response;
    }

    private NoteVersionResponse toVersionResponse(NoteVersion version) {
        NoteVersionResponse response = new NoteVersionResponse();
        response.setId(version.getId());
        response.setTenantId(version.getTenantId());
        response.setNoteId(version.getNoteId());
        response.setVersionNo(version.getVersionNo());
        response.setContentMd(version.getContentMd());
        response.setContentHash(version.getContentHash());
        response.setContentGuidedJson(version.getContentGuidedJson());
        response.setChangeSummary(version.getChangeSummary());
        response.setCreatedBy(version.getCreatedBy());
        response.setCreatedAt(version.getCreatedAt());
        return response;
    }
}
