package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.ConceptProgressResponse;
import com.learning.user_profile_service.model.dto.RecordExamResultRequest;
import com.learning.user_profile_service.model.dto.RecordFlashcardReviewRequest;
import com.learning.user_profile_service.model.dto.RecordReadingSessionRequest;
import com.learning.user_profile_service.service.ConceptProgressService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/users/{userId}/progress/concepts")
public class ConceptProgressController {

    private final ConceptProgressService conceptProgressService;

    @PostMapping("/exam-result")
    @ResponseStatus(HttpStatus.CREATED)
    public ConceptProgressResponse recordExamResult(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @Valid @RequestBody RecordExamResultRequest request) {
        return conceptProgressService.recordExamResult(tenantId, userId, request);
    }

    @PostMapping("/flashcard-review")
    @ResponseStatus(HttpStatus.CREATED)
    public ConceptProgressResponse recordFlashcardReview(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @Valid @RequestBody RecordFlashcardReviewRequest request) {
        return conceptProgressService.recordFlashcardReview(tenantId, userId, request);
    }

    @PostMapping("/reading-session")
    @ResponseStatus(HttpStatus.CREATED)
    public ConceptProgressResponse recordReadingSession(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @Valid @RequestBody RecordReadingSessionRequest request) {
        return conceptProgressService.recordReadingSession(tenantId, userId, request);
    }

    @GetMapping
    public List<ConceptProgressResponse> listConceptProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return conceptProgressService.listConceptProgress(tenantId, userId);
    }

    @GetMapping("/{noteId}")
    public ConceptProgressResponse getConceptProgress(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @PathVariable UUID noteId) {
        return conceptProgressService.getConceptProgress(tenantId, userId, noteId);
    }

    @GetMapping("/{noteId}/retention")
    public Double getRetention(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @PathVariable UUID noteId) {
        return conceptProgressService.getRetention(tenantId, userId, noteId);
    }

    @GetMapping("/decaying")
    public List<ConceptProgressResponse> listDecayingConcepts(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0.5") double threshold) {
        return conceptProgressService.listDecayingConcepts(tenantId, userId, threshold);
    }
}
