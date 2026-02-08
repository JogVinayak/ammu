package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.BatchMcqsRequest;
import com.learning.notes_service.model.dto.CreateMcqRequest;
import com.learning.notes_service.model.dto.McqListResponse;
import com.learning.notes_service.model.dto.McqResponse;
import com.learning.notes_service.model.dto.UpdateMcqRequest;
import java.util.UUID;

public interface McqService {

    McqResponse create(UUID tenantId, UUID noteId, CreateMcqRequest request);

    McqListResponse listByNote(UUID tenantId, UUID noteId);

    McqListResponse listByNoteAndDifficulty(UUID tenantId, UUID noteId, String difficulty);

    McqResponse getById(UUID tenantId, UUID noteId, UUID mcqId);

    McqResponse update(UUID tenantId, UUID noteId, UUID mcqId, UpdateMcqRequest request);

    void delete(UUID tenantId, UUID noteId, UUID mcqId);

    McqListResponse batchUpsert(UUID tenantId, UUID noteId, BatchMcqsRequest request);
}
