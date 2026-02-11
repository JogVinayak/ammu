package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.ExamAnswerResponse;
import com.learning.notes_service.model.dto.ExamAttemptListResponse;
import com.learning.notes_service.model.dto.ExamAttemptResponse;
import com.learning.notes_service.model.dto.ExamAttemptSummaryResponse;
import com.learning.notes_service.model.dto.StartExamAttemptRequest;
import com.learning.notes_service.model.dto.SubmitAnswerRequest;
import com.learning.notes_service.model.dto.SubmitExamRequest;
import java.util.UUID;

public interface ExamAttemptService {

    ExamAttemptResponse startAttempt(UUID tenantId, UUID noteId, StartExamAttemptRequest request);

    ExamAnswerResponse submitAnswer(UUID tenantId, UUID attemptId, SubmitAnswerRequest request);

    ExamAttemptResponse completeAttempt(UUID tenantId, UUID attemptId);

    ExamAttemptResponse abandonAttempt(UUID tenantId, UUID attemptId);

    ExamAttemptResponse submitExam(UUID tenantId, UUID noteId, SubmitExamRequest request);

    ExamAttemptResponse getAttempt(UUID tenantId, UUID attemptId);

    ExamAttemptListResponse listAttempts(UUID tenantId, UUID noteId, UUID studentId);

    ExamAttemptSummaryResponse getAttemptSummary(UUID tenantId, UUID noteId, UUID studentId);
}
