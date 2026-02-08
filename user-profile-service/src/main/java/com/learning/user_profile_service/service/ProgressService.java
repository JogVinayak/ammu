package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ContentProgressResponse;
import com.learning.user_profile_service.model.dto.KnowledgeCoverageResponse;
import com.learning.user_profile_service.model.dto.MindmapCoverageResponse;
import com.learning.user_profile_service.model.dto.RecordNodeReviewRequest;
import com.learning.user_profile_service.model.dto.RecordProgressRequest;
import com.learning.user_profile_service.model.dto.UserProgressResponse;
import com.learning.user_profile_service.model.enums.ContentType;
import java.util.List;
import java.util.UUID;

public interface ProgressService {
    // User aggregate progress
    UserProgressResponse getUserProgress(UUID tenantId, UUID userId);

    // Content progress
    ContentProgressResponse recordProgress(UUID tenantId, UUID userId, RecordProgressRequest request);
    ContentProgressResponse getContentProgress(UUID tenantId, UUID userId, UUID contentId, ContentType contentType);
    List<ContentProgressResponse> getUserContentProgress(UUID tenantId, UUID userId);
    List<ContentProgressResponse> getUserContentProgressByType(UUID tenantId, UUID userId, ContentType contentType);

    // Knowledge coverage
    KnowledgeCoverageResponse recordNodeReview(UUID tenantId, UUID userId, RecordNodeReviewRequest request);
    MindmapCoverageResponse getMindmapCoverage(UUID tenantId, UUID userId, UUID mindmapId, int totalNodes);
    List<KnowledgeCoverageResponse> getDueForReview(UUID userId, int limit);
}
