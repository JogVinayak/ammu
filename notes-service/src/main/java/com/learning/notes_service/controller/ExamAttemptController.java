package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.ExamAnswerResponse;
import com.learning.notes_service.model.dto.ExamAttemptListResponse;
import com.learning.notes_service.model.dto.ExamAttemptResponse;
import com.learning.notes_service.model.dto.ExamAttemptSummaryResponse;
import com.learning.notes_service.model.dto.StartExamAttemptRequest;
import com.learning.notes_service.model.dto.SubmitAnswerRequest;
import com.learning.notes_service.model.dto.SubmitExamRequest;
import com.learning.notes_service.service.ExamAttemptService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/notes/{noteId}/deck/exam-attempts")
public class ExamAttemptController {

    private final ExamAttemptService examAttemptService;

    @PostMapping("/start")
    public ResponseEntity<ExamAttemptResponse> startAttempt(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody StartExamAttemptRequest request) {
        ExamAttemptResponse response = examAttemptService.startAttempt(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/{attemptId}/answers")
    public ResponseEntity<ExamAnswerResponse> submitAnswer(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID attemptId,
            @RequestBody SubmitAnswerRequest request) {
        ExamAnswerResponse response = examAttemptService.submitAnswer(tenantId, attemptId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/{attemptId}/complete")
    public ExamAttemptResponse completeAttempt(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID attemptId) {
        return examAttemptService.completeAttempt(tenantId, attemptId);
    }

    @PostMapping("/{attemptId}/abandon")
    public ExamAttemptResponse abandonAttempt(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID attemptId) {
        return examAttemptService.abandonAttempt(tenantId, attemptId);
    }

    @PostMapping("/submit")
    public ResponseEntity<ExamAttemptResponse> submitExam(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestBody SubmitExamRequest request) {
        ExamAttemptResponse response = examAttemptService.submitExam(tenantId, noteId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{attemptId}")
    public ExamAttemptResponse getAttempt(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID attemptId) {
        return examAttemptService.getAttempt(tenantId, attemptId);
    }

    @GetMapping
    public ExamAttemptListResponse listAttempts(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID studentId) {
        return examAttemptService.listAttempts(tenantId, noteId, studentId);
    }

    @GetMapping("/summary")
    public ExamAttemptSummaryResponse getAttemptSummary(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam UUID studentId) {
        return examAttemptService.getAttemptSummary(tenantId, noteId, studentId);
    }
}
