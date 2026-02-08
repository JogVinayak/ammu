package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.BatchMcqsRequest;
import com.learning.notes_service.model.dto.CreateMcqRequest;
import com.learning.notes_service.model.dto.McqListResponse;
import com.learning.notes_service.model.dto.McqResponse;
import com.learning.notes_service.model.dto.UpdateMcqRequest;
import com.learning.notes_service.model.entity.Mcq;
import com.learning.notes_service.repository.McqRepository;
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
public class DefaultMcqService implements McqService {

    private final McqRepository mcqRepository;
    private final NoteRepository noteRepository;

    @Override
    @Transactional
    public McqResponse create(UUID tenantId, UUID noteId, CreateMcqRequest request) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        Instant now = Instant.now();
        Integer position = request.getPosition();
        if (position == null) {
            position = mcqRepository.findMaxPosition(tenantId, noteId) + 1;
        }

        Mcq mcq = new Mcq();
        mcq.setId(UUID.randomUUID());
        mcq.setTenantId(tenantId);
        mcq.setNoteId(noteId);
        mcq.setQuestionText(request.getQuestionText());
        mcq.setOptionsJson(request.getOptionsJson());
        mcq.setDifficulty(request.getDifficulty() != null ? request.getDifficulty() : "MEDIUM");
        mcq.setExplanation(request.getExplanation());
        mcq.setPosition(position);
        mcq.setCreatedBy(request.getCreatedBy());
        mcq.setCreatedAt(now);
        mcq.setUpdatedAt(now);

        mcqRepository.save(mcq);
        return toResponse(mcq);
    }

    @Override
    @Transactional(readOnly = true)
    public McqListResponse listByNote(UUID tenantId, UUID noteId) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        List<Mcq> mcqs = mcqRepository
                .findByTenantIdAndNoteIdOrderByPositionAsc(tenantId, noteId);

        McqListResponse response = new McqListResponse();
        response.setNoteId(noteId);
        response.setItems(mcqs.stream().map(this::toResponse).collect(Collectors.toList()));
        response.setTotal(mcqs.size());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public McqListResponse listByNoteAndDifficulty(UUID tenantId, UUID noteId, String difficulty) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        List<Mcq> mcqs = mcqRepository
                .findByTenantIdAndNoteIdAndDifficultyOrderByPositionAsc(tenantId, noteId, difficulty);

        McqListResponse response = new McqListResponse();
        response.setNoteId(noteId);
        response.setItems(mcqs.stream().map(this::toResponse).collect(Collectors.toList()));
        response.setTotal(mcqs.size());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public McqResponse getById(UUID tenantId, UUID noteId, UUID mcqId) {
        Mcq mcq = mcqRepository.findByIdAndTenantId(mcqId, tenantId)
                .orElseThrow(() -> new RuntimeException("MCQ not found"));

        if (!mcq.getNoteId().equals(noteId)) {
            throw new RuntimeException("MCQ does not belong to this note");
        }

        return toResponse(mcq);
    }

    @Override
    @Transactional
    public McqResponse update(UUID tenantId, UUID noteId, UUID mcqId,
                               UpdateMcqRequest request) {
        Mcq mcq = mcqRepository.findByIdAndTenantId(mcqId, tenantId)
                .orElseThrow(() -> new RuntimeException("MCQ not found"));

        if (!mcq.getNoteId().equals(noteId)) {
            throw new RuntimeException("MCQ does not belong to this note");
        }

        if (request.getQuestionText() != null) {
            mcq.setQuestionText(request.getQuestionText());
        }
        if (request.getOptionsJson() != null) {
            mcq.setOptionsJson(request.getOptionsJson());
        }
        if (request.getDifficulty() != null) {
            mcq.setDifficulty(request.getDifficulty());
        }
        if (request.getExplanation() != null) {
            mcq.setExplanation(request.getExplanation());
        }
        if (request.getPosition() != null) {
            mcq.setPosition(request.getPosition());
        }
        mcq.setUpdatedAt(Instant.now());

        mcqRepository.save(mcq);
        return toResponse(mcq);
    }

    @Override
    @Transactional
    public void delete(UUID tenantId, UUID noteId, UUID mcqId) {
        Mcq mcq = mcqRepository.findByIdAndTenantId(mcqId, tenantId)
                .orElseThrow(() -> new RuntimeException("MCQ not found"));

        if (!mcq.getNoteId().equals(noteId)) {
            throw new RuntimeException("MCQ does not belong to this note");
        }

        mcqRepository.delete(mcq);
    }

    @Override
    @Transactional
    public McqListResponse batchUpsert(UUID tenantId, UUID noteId,
                                        BatchMcqsRequest request) {
        // Verify note exists
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new RuntimeException("Note not found"));

        Instant now = Instant.now();

        if (request.isReplaceAll()) {
            mcqRepository.deleteByTenantIdAndNoteId(tenantId, noteId);
        }

        for (int i = 0; i < request.getMcqs().size(); i++) {
            BatchMcqsRequest.McqItem item = request.getMcqs().get(i);

            Mcq mcq;
            if (item.getId() != null && !request.isReplaceAll()) {
                mcq = mcqRepository.findByIdAndTenantId(item.getId(), tenantId)
                        .orElse(new Mcq());
                if (mcq.getId() == null) {
                    mcq.setId(UUID.randomUUID());
                    mcq.setCreatedAt(now);
                    mcq.setCreatedBy(request.getCreatedBy());
                }
            } else {
                mcq = new Mcq();
                mcq.setId(UUID.randomUUID());
                mcq.setCreatedAt(now);
                mcq.setCreatedBy(request.getCreatedBy());
            }

            mcq.setTenantId(tenantId);
            mcq.setNoteId(noteId);
            mcq.setQuestionText(item.getQuestionText());
            mcq.setOptionsJson(item.getOptionsJson());
            mcq.setDifficulty(item.getDifficulty() != null ? item.getDifficulty() : "MEDIUM");
            mcq.setExplanation(item.getExplanation());
            mcq.setPosition(item.getPosition() != null ? item.getPosition() : i + 1);
            mcq.setUpdatedAt(now);

            mcqRepository.save(mcq);
        }

        return listByNote(tenantId, noteId);
    }

    private McqResponse toResponse(Mcq mcq) {
        McqResponse response = new McqResponse();
        response.setId(mcq.getId());
        response.setNoteId(mcq.getNoteId());
        response.setQuestionText(mcq.getQuestionText());
        response.setOptionsJson(mcq.getOptionsJson());
        response.setDifficulty(mcq.getDifficulty());
        response.setExplanation(mcq.getExplanation());
        response.setPosition(mcq.getPosition());
        response.setCreatedBy(mcq.getCreatedBy());
        response.setCreatedAt(mcq.getCreatedAt());
        response.setUpdatedAt(mcq.getUpdatedAt());
        return response;
    }
}
