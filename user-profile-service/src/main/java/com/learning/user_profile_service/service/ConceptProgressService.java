package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ConceptProgressResponse;
import com.learning.user_profile_service.model.dto.RecordExamResultRequest;
import com.learning.user_profile_service.model.dto.RecordFlashcardReviewRequest;
import com.learning.user_profile_service.model.dto.RecordReadingSessionRequest;
import java.util.List;
import java.util.UUID;

public interface ConceptProgressService {

    ConceptProgressResponse recordExamResult(UUID tenantId, UUID userId,
                                              RecordExamResultRequest request);

    ConceptProgressResponse recordFlashcardReview(UUID tenantId, UUID userId,
                                                   RecordFlashcardReviewRequest request);

    ConceptProgressResponse recordReadingSession(UUID tenantId, UUID userId,
                                                  RecordReadingSessionRequest request);

    ConceptProgressResponse getConceptProgress(UUID tenantId, UUID userId, UUID noteId);

    List<ConceptProgressResponse> listConceptProgress(UUID tenantId, UUID userId);

    Double getRetention(UUID tenantId, UUID userId, UUID noteId);

    List<ConceptProgressResponse> listDecayingConcepts(UUID tenantId, UUID userId,
                                                        double threshold);
}
