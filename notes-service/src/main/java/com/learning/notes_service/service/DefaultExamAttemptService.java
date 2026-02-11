package com.learning.notes_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.notes_service.exception.NotFoundException;
import com.learning.notes_service.model.dto.ExamAnswerResponse;
import com.learning.notes_service.model.dto.ExamAttemptListResponse;
import com.learning.notes_service.model.dto.ExamAttemptResponse;
import com.learning.notes_service.model.dto.ExamAttemptSummaryResponse;
import com.learning.notes_service.model.dto.StartExamAttemptRequest;
import com.learning.notes_service.model.dto.SubmitAnswerRequest;
import com.learning.notes_service.model.dto.SubmitExamRequest;
import com.learning.notes_service.model.entity.Deck;
import com.learning.notes_service.model.entity.ExamAnswer;
import com.learning.notes_service.model.entity.ExamAttempt;
import com.learning.notes_service.model.entity.Mcq;
import com.learning.notes_service.model.enums.DeckStatus;
import com.learning.notes_service.model.enums.ExamAttemptStatus;
import com.learning.notes_service.repository.DeckRepository;
import com.learning.notes_service.repository.ExamAnswerRepository;
import com.learning.notes_service.repository.ExamAttemptRepository;
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
public class DefaultExamAttemptService implements ExamAttemptService {

    private static final int PASS_THRESHOLD = 80;

    private final ExamAttemptRepository examAttemptRepository;
    private final ExamAnswerRepository examAnswerRepository;
    private final DeckRepository deckRepository;
    private final McqRepository mcqRepository;
    private final NoteRepository noteRepository;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public ExamAttemptResponse startAttempt(UUID tenantId, UUID noteId,
                                             StartExamAttemptRequest request) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        Deck deck = deckRepository.findByTenantIdAndNoteId(tenantId, noteId)
                .orElseThrow(() -> new NotFoundException("Deck not found for this note"));

        if (deck.getStatus() != DeckStatus.ACTIVE) {
            throw new IllegalStateException("Deck must be ACTIVE to start an exam");
        }

        long mcqCount = mcqRepository.countByTenantIdAndNoteId(tenantId, noteId);
        if (mcqCount == 0) {
            throw new IllegalStateException("No MCQs available for this deck");
        }

        Instant now = Instant.now();
        ExamAttempt attempt = new ExamAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setTenantId(tenantId);
        attempt.setNoteId(noteId);
        attempt.setDeckId(deck.getId());
        attempt.setStudentId(request.getStudentId());
        attempt.setTotalQuestions((int) mcqCount);
        attempt.setStatus(ExamAttemptStatus.IN_PROGRESS);
        attempt.setStartedAt(now);
        attempt.setCreatedAt(now);

        examAttemptRepository.save(attempt);
        return toResponse(attempt, null);
    }

    @Override
    @Transactional
    public ExamAnswerResponse submitAnswer(UUID tenantId, UUID attemptId,
                                            SubmitAnswerRequest request) {
        ExamAttempt attempt = examAttemptRepository.findByIdAndTenantId(attemptId, tenantId)
                .orElseThrow(() -> new NotFoundException("Exam attempt not found"));

        if (attempt.getStatus() != ExamAttemptStatus.IN_PROGRESS) {
            throw new IllegalStateException("Attempt is not in progress");
        }

        if (examAnswerRepository.existsByTenantIdAndExamAttemptIdAndMcqId(
                tenantId, attemptId, request.getMcqId())) {
            throw new IllegalStateException("Answer already submitted for this MCQ");
        }

        Mcq mcq = mcqRepository.findByIdAndTenantId(request.getMcqId(), tenantId)
                .orElseThrow(() -> new NotFoundException("MCQ not found"));

        if (!mcq.getNoteId().equals(attempt.getNoteId())) {
            throw new IllegalStateException("MCQ does not belong to this exam's note");
        }

        boolean isCorrect = checkAnswer(mcq.getOptionsJson(), request.getSelectedOptionIndex());

        ExamAnswer answer = new ExamAnswer();
        answer.setId(UUID.randomUUID());
        answer.setTenantId(tenantId);
        answer.setExamAttemptId(attemptId);
        answer.setMcqId(request.getMcqId());
        answer.setSelectedOptionIndex(request.getSelectedOptionIndex());
        answer.setCorrect(isCorrect);
        answer.setAnsweredAt(Instant.now());

        examAnswerRepository.save(answer);
        return toAnswerResponse(answer);
    }

    @Override
    @Transactional
    public ExamAttemptResponse completeAttempt(UUID tenantId, UUID attemptId) {
        ExamAttempt attempt = examAttemptRepository.findByIdAndTenantId(attemptId, tenantId)
                .orElseThrow(() -> new NotFoundException("Exam attempt not found"));

        if (attempt.getStatus() != ExamAttemptStatus.IN_PROGRESS) {
            throw new IllegalStateException("Attempt is not in progress");
        }

        long correctCount = examAnswerRepository
                .countByTenantIdAndExamAttemptIdAndCorrectTrue(tenantId, attemptId);
        int scorePercent = (int) Math.round((correctCount * 100.0) / attempt.getTotalQuestions());

        attempt.setCorrectCount((int) correctCount);
        attempt.setScorePercent(scorePercent);
        attempt.setPassed(scorePercent >= PASS_THRESHOLD);
        attempt.setStatus(ExamAttemptStatus.COMPLETED);
        attempt.setCompletedAt(Instant.now());

        examAttemptRepository.save(attempt);

        List<ExamAnswer> answers = examAnswerRepository
                .findByTenantIdAndExamAttemptIdOrderByAnsweredAtAsc(tenantId, attemptId);
        return toResponse(attempt, answers);
    }

    @Override
    @Transactional
    public ExamAttemptResponse abandonAttempt(UUID tenantId, UUID attemptId) {
        ExamAttempt attempt = examAttemptRepository.findByIdAndTenantId(attemptId, tenantId)
                .orElseThrow(() -> new NotFoundException("Exam attempt not found"));

        if (attempt.getStatus() != ExamAttemptStatus.IN_PROGRESS) {
            throw new IllegalStateException("Attempt is not in progress");
        }

        attempt.setStatus(ExamAttemptStatus.ABANDONED);
        attempt.setCompletedAt(Instant.now());
        examAttemptRepository.save(attempt);
        return toResponse(attempt, null);
    }

    @Override
    @Transactional
    public ExamAttemptResponse submitExam(UUID tenantId, UUID noteId,
                                           SubmitExamRequest request) {
        StartExamAttemptRequest startReq = new StartExamAttemptRequest();
        startReq.setStudentId(request.getStudentId());
        ExamAttemptResponse started = startAttempt(tenantId, noteId, startReq);

        for (SubmitExamRequest.AnswerItem item : request.getAnswers()) {
            SubmitAnswerRequest answerReq = new SubmitAnswerRequest();
            answerReq.setMcqId(item.getMcqId());
            answerReq.setSelectedOptionIndex(item.getSelectedOptionIndex());
            submitAnswer(tenantId, started.getId(), answerReq);
        }

        return completeAttempt(tenantId, started.getId());
    }

    @Override
    @Transactional(readOnly = true)
    public ExamAttemptResponse getAttempt(UUID tenantId, UUID attemptId) {
        ExamAttempt attempt = examAttemptRepository.findByIdAndTenantId(attemptId, tenantId)
                .orElseThrow(() -> new NotFoundException("Exam attempt not found"));
        List<ExamAnswer> answers = examAnswerRepository
                .findByTenantIdAndExamAttemptIdOrderByAnsweredAtAsc(tenantId, attemptId);
        return toResponse(attempt, answers);
    }

    @Override
    @Transactional(readOnly = true)
    public ExamAttemptListResponse listAttempts(UUID tenantId, UUID noteId, UUID studentId) {
        List<ExamAttempt> attempts = examAttemptRepository
                .findByTenantIdAndNoteIdAndStudentIdOrderByCreatedAtDesc(
                        tenantId, noteId, studentId);

        ExamAttemptListResponse response = new ExamAttemptListResponse();
        response.setNoteId(noteId);
        response.setStudentId(studentId);
        response.setItems(attempts.stream()
                .map(a -> toResponse(a, null))
                .collect(Collectors.toList()));
        response.setTotal(attempts.size());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public ExamAttemptSummaryResponse getAttemptSummary(UUID tenantId, UUID noteId,
                                                         UUID studentId) {
        ExamAttemptSummaryResponse summary = new ExamAttemptSummaryResponse();
        summary.setNoteId(noteId);
        summary.setStudentId(studentId);
        summary.setTotalAttempts(
                examAttemptRepository.countCompletedAttempts(tenantId, noteId, studentId));
        summary.setBestScore(
                examAttemptRepository.findBestScore(tenantId, noteId, studentId));
        summary.setAverageScore(
                examAttemptRepository.findAverageScore(tenantId, noteId, studentId));
        summary.setPassedCount(
                examAttemptRepository.countPassedAttempts(tenantId, noteId, studentId));
        summary.setHasPassed(summary.getPassedCount() > 0);
        return summary;
    }

    private boolean checkAnswer(String optionsJson, int selectedIndex) {
        try {
            JsonNode options = objectMapper.readTree(optionsJson);
            if (selectedIndex < 0 || selectedIndex >= options.size()) {
                throw new IllegalArgumentException("Invalid option index: " + selectedIndex);
            }
            JsonNode selected = options.get(selectedIndex);
            return selected.has("isCorrect") && selected.get("isCorrect").asBoolean();
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to parse MCQ options", e);
        }
    }

    private ExamAttemptResponse toResponse(ExamAttempt attempt, List<ExamAnswer> answers) {
        ExamAttemptResponse response = new ExamAttemptResponse();
        response.setId(attempt.getId());
        response.setNoteId(attempt.getNoteId());
        response.setDeckId(attempt.getDeckId());
        response.setStudentId(attempt.getStudentId());
        response.setTotalQuestions(attempt.getTotalQuestions());
        response.setCorrectCount(attempt.getCorrectCount());
        response.setScorePercent(attempt.getScorePercent());
        response.setPassed(attempt.getPassed());
        response.setStatus(attempt.getStatus().name());
        response.setStartedAt(attempt.getStartedAt());
        response.setCompletedAt(attempt.getCompletedAt());
        response.setCreatedAt(attempt.getCreatedAt());
        if (answers != null) {
            response.setAnswers(answers.stream()
                    .map(this::toAnswerResponse)
                    .collect(Collectors.toList()));
        }
        return response;
    }

    private ExamAnswerResponse toAnswerResponse(ExamAnswer answer) {
        ExamAnswerResponse response = new ExamAnswerResponse();
        response.setId(answer.getId());
        response.setMcqId(answer.getMcqId());
        response.setSelectedOptionIndex(answer.getSelectedOptionIndex());
        response.setCorrect(answer.getCorrect());
        response.setAnsweredAt(answer.getAnsweredAt());
        return response;
    }
}
