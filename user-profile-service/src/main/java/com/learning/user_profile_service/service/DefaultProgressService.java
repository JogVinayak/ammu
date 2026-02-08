package com.learning.user_profile_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.user_profile_service.model.dto.ContentProgressResponse;
import com.learning.user_profile_service.model.dto.KnowledgeCoverageResponse;
import com.learning.user_profile_service.model.dto.MindmapCoverageResponse;
import com.learning.user_profile_service.model.dto.RecordNodeReviewRequest;
import com.learning.user_profile_service.model.dto.RecordProgressRequest;
import com.learning.user_profile_service.model.dto.UserProgressResponse;
import com.learning.user_profile_service.model.entity.ContentProgress;
import com.learning.user_profile_service.model.entity.KnowledgeCoverage;
import com.learning.user_profile_service.model.entity.ProgressEvent;
import com.learning.user_profile_service.model.entity.UserProgress;
import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.MasteryLevel;
import com.learning.user_profile_service.model.enums.ProgressEventType;
import com.learning.user_profile_service.model.enums.ProgressStatus;
import com.learning.user_profile_service.repository.ContentProgressRepository;
import com.learning.user_profile_service.repository.KnowledgeCoverageRepository;
import com.learning.user_profile_service.repository.ProgressEventRepository;
import com.learning.user_profile_service.repository.UserProgressRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DefaultProgressService implements ProgressService {

    private final UserProgressRepository userProgressRepository;
    private final ContentProgressRepository contentProgressRepository;
    private final KnowledgeCoverageRepository knowledgeCoverageRepository;
    private final ProgressEventRepository progressEventRepository;
    private final ObjectMapper objectMapper;

    @Override
    public UserProgressResponse getUserProgress(UUID tenantId, UUID userId) {
        UserProgress progress = userProgressRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseGet(() -> createUserProgress(tenantId, userId));
        return mapToUserProgressResponse(progress);
    }

    @Override
    @Transactional
    public ContentProgressResponse recordProgress(UUID tenantId, UUID userId, RecordProgressRequest request) {
        ContentProgress progress = contentProgressRepository
                .findByTenantIdAndUserIdAndContentIdAndContentType(
                        tenantId, userId, request.getContentId(), request.getContentType())
                .orElseGet(() -> createContentProgress(tenantId, userId, request.getContentId(), request.getContentType()));

        Instant now = Instant.now();

        // Update progress based on event type
        if (request.getEventType() == ProgressEventType.CONTENT_STARTED && progress.getStartedAt() == null) {
            progress.setStartedAt(now);
            progress.setStatus(ProgressStatus.IN_PROGRESS);
        }

        if (request.getProgressPercent() != null) {
            progress.setProgressPercent(request.getProgressPercent());
        }

        if (request.getScore() != null) {
            progress.setScore(request.getScore());
            progress.setAttempts(progress.getAttempts() + 1);
        }

        if (request.getTimeSpentSeconds() != null) {
            progress.setTimeSpentSeconds(progress.getTimeSpentSeconds() + request.getTimeSpentSeconds());
        }

        if (request.getLastPosition() != null) {
            progress.setLastPosition(request.getLastPosition());
        }

        if (request.getEventType() == ProgressEventType.CONTENT_COMPLETED) {
            progress.setStatus(ProgressStatus.COMPLETED);
            progress.setCompletedAt(now);
            progress.setProgressPercent(100);
        }

        progress.setUpdatedAt(now);
        contentProgressRepository.save(progress);

        // Record event
        recordProgressEvent(tenantId, userId, request);

        // Update aggregate progress
        updateUserAggregateProgress(tenantId, userId, request);

        return mapToContentProgressResponse(progress);
    }

    @Override
    public ContentProgressResponse getContentProgress(UUID tenantId, UUID userId, UUID contentId, ContentType contentType) {
        return contentProgressRepository
                .findByTenantIdAndUserIdAndContentIdAndContentType(tenantId, userId, contentId, contentType)
                .map(this::mapToContentProgressResponse)
                .orElse(null);
    }

    @Override
    public List<ContentProgressResponse> getUserContentProgress(UUID tenantId, UUID userId) {
        return contentProgressRepository.findByTenantIdAndUserId(tenantId, userId)
                .stream()
                .map(this::mapToContentProgressResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<ContentProgressResponse> getUserContentProgressByType(UUID tenantId, UUID userId, ContentType contentType) {
        return contentProgressRepository.findByTenantIdAndUserIdAndContentType(tenantId, userId, contentType)
                .stream()
                .map(this::mapToContentProgressResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public KnowledgeCoverageResponse recordNodeReview(UUID tenantId, UUID userId, RecordNodeReviewRequest request) {
        KnowledgeCoverage coverage = knowledgeCoverageRepository
                .findByTenantIdAndUserIdAndMindmapIdAndNodeId(
                        tenantId, userId, request.getMindmapId(), request.getNodeId())
                .orElseGet(() -> createKnowledgeCoverage(tenantId, userId, request.getMindmapId(), request.getNodeId()));

        Instant now = Instant.now();

        coverage.setReviewCount(coverage.getReviewCount() + 1);
        if (Boolean.TRUE.equals(request.getCorrect())) {
            coverage.setCorrectCount(coverage.getCorrectCount() + 1);
        }

        // Calculate confidence score
        double correctRatio = (double) coverage.getCorrectCount() / coverage.getReviewCount();
        coverage.setConfidenceScore(BigDecimal.valueOf(correctRatio * 100).setScale(2, RoundingMode.HALF_UP));

        // Update mastery level based on confidence
        coverage.setMasteryLevel(calculateMasteryLevel(coverage.getConfidenceScore(), coverage.getReviewCount()));

        coverage.setLastReviewedAt(now);
        coverage.setNextReviewAt(calculateNextReviewTime(coverage.getMasteryLevel(), now));
        coverage.setUpdatedAt(now);

        knowledgeCoverageRepository.save(coverage);

        return mapToKnowledgeCoverageResponse(coverage);
    }

    @Override
    public MindmapCoverageResponse getMindmapCoverage(UUID tenantId, UUID userId, UUID mindmapId, int totalNodes) {
        List<KnowledgeCoverage> coverages = knowledgeCoverageRepository
                .findByTenantIdAndUserIdAndMindmapId(tenantId, userId, mindmapId);

        int nodesStarted = coverages.size();
        long nodesMastered = coverages.stream()
                .filter(c -> c.getMasteryLevel() == MasteryLevel.MASTERED || c.getMasteryLevel() == MasteryLevel.PROFICIENT)
                .count();

        BigDecimal coveragePercent = totalNodes > 0
                ? BigDecimal.valueOf((double) nodesStarted / totalNodes * 100).setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal avgConfidence = coverages.isEmpty()
                ? BigDecimal.ZERO
                : coverages.stream()
                        .map(KnowledgeCoverage::getConfidenceScore)
                        .filter(s -> s != null)
                        .reduce(BigDecimal.ZERO, BigDecimal::add)
                        .divide(BigDecimal.valueOf(coverages.size()), 2, RoundingMode.HALF_UP);

        return MindmapCoverageResponse.builder()
                .mindmapId(mindmapId)
                .totalNodes(totalNodes)
                .nodesStarted(nodesStarted)
                .nodesMastered((int) nodesMastered)
                .coveragePercent(coveragePercent)
                .averageConfidence(avgConfidence)
                .nodeCoverage(coverages.stream().map(this::mapToKnowledgeCoverageResponse).collect(Collectors.toList()))
                .build();
    }

    @Override
    public List<KnowledgeCoverageResponse> getDueForReview(UUID userId, int limit) {
        return knowledgeCoverageRepository
                .findByUserIdAndNextReviewAtBeforeOrderByNextReviewAtAsc(userId, Instant.now())
                .stream()
                .limit(limit)
                .map(this::mapToKnowledgeCoverageResponse)
                .collect(Collectors.toList());
    }

    // Helper methods

    private UserProgress createUserProgress(UUID tenantId, UUID userId) {
        UserProgress progress = new UserProgress();
        progress.setId(UUID.randomUUID());
        progress.setTenantId(tenantId);
        progress.setUserId(userId);
        progress.setCreatedAt(Instant.now());
        progress.setUpdatedAt(Instant.now());
        return userProgressRepository.save(progress);
    }

    private ContentProgress createContentProgress(UUID tenantId, UUID userId, UUID contentId, ContentType contentType) {
        ContentProgress progress = new ContentProgress();
        progress.setId(UUID.randomUUID());
        progress.setTenantId(tenantId);
        progress.setUserId(userId);
        progress.setContentId(contentId);
        progress.setContentType(contentType);
        progress.setStatus(ProgressStatus.NOT_STARTED);
        progress.setCreatedAt(Instant.now());
        progress.setUpdatedAt(Instant.now());
        return progress;
    }

    private KnowledgeCoverage createKnowledgeCoverage(UUID tenantId, UUID userId, UUID mindmapId, UUID nodeId) {
        KnowledgeCoverage coverage = new KnowledgeCoverage();
        coverage.setId(UUID.randomUUID());
        coverage.setTenantId(tenantId);
        coverage.setUserId(userId);
        coverage.setMindmapId(mindmapId);
        coverage.setNodeId(nodeId);
        coverage.setMasteryLevel(MasteryLevel.NOT_STARTED);
        coverage.setCreatedAt(Instant.now());
        coverage.setUpdatedAt(Instant.now());
        return coverage;
    }

    private void recordProgressEvent(UUID tenantId, UUID userId, RecordProgressRequest request) {
        ProgressEvent event = new ProgressEvent();
        event.setId(UUID.randomUUID());
        event.setTenantId(tenantId);
        event.setUserId(userId);
        event.setEventType(request.getEventType());
        event.setContentId(request.getContentId());
        event.setContentType(request.getContentType());
        if (request.getEventData() != null) {
            try {
                event.setEventData(objectMapper.writeValueAsString(request.getEventData()));
            } catch (JsonProcessingException e) {
                log.warn("Failed to serialize event data", e);
            }
        }
        event.setCreatedAt(Instant.now());
        progressEventRepository.save(event);
    }

    private void updateUserAggregateProgress(UUID tenantId, UUID userId, RecordProgressRequest request) {
        UserProgress progress = userProgressRepository.findByTenantIdAndUserId(tenantId, userId)
                .orElseGet(() -> createUserProgress(tenantId, userId));

        Instant now = Instant.now();

        // Update counters based on event type
        if (request.getEventType() == ProgressEventType.CONTENT_STARTED) {
            if (request.getContentType() == ContentType.NOTE) {
                progress.setTotalNotesViewed(progress.getTotalNotesViewed() + 1);
            } else if (request.getContentType() == ContentType.MINDMAP) {
                progress.setTotalMindmapsViewed(progress.getTotalMindmapsViewed() + 1);
            }
        } else if (request.getEventType() == ProgressEventType.CONTENT_COMPLETED) {
            if (request.getContentType() == ContentType.NOTE) {
                progress.setTotalNotesCompleted(progress.getTotalNotesCompleted() + 1);
            } else if (request.getContentType() == ContentType.MINDMAP) {
                progress.setTotalMindmapsCompleted(progress.getTotalMindmapsCompleted() + 1);
            }
        } else if (request.getEventType() == ProgressEventType.FLASHCARD_REVIEWED) {
            progress.setTotalFlashcardsReviewed(progress.getTotalFlashcardsReviewed() + 1);
        } else if (request.getEventType() == ProgressEventType.QUIZ_SUBMITTED) {
            progress.setTotalQuizzesAttempted(progress.getTotalQuizzesAttempted() + 1);
            // Update average quiz score
            if (request.getScore() != null) {
                BigDecimal currentAvg = progress.getAverageQuizScore() != null
                        ? progress.getAverageQuizScore()
                        : BigDecimal.ZERO;
                int attempts = progress.getTotalQuizzesAttempted();
                BigDecimal newAvg = currentAvg.multiply(BigDecimal.valueOf(attempts - 1))
                        .add(request.getScore())
                        .divide(BigDecimal.valueOf(attempts), 2, RoundingMode.HALF_UP);
                progress.setAverageQuizScore(newAvg);
            }
        }

        // Update time spent
        if (request.getTimeSpentSeconds() != null) {
            progress.setTotalTimeSpentSeconds(progress.getTotalTimeSpentSeconds() + request.getTimeSpentSeconds());
        }

        // Update streak
        if (progress.getLastActivityAt() != null) {
            long daysSinceLastActivity = ChronoUnit.DAYS.between(progress.getLastActivityAt(), now);
            if (daysSinceLastActivity == 1) {
                progress.setStreakDays(progress.getStreakDays() + 1);
            } else if (daysSinceLastActivity > 1) {
                progress.setStreakDays(1);
            }
        } else {
            progress.setStreakDays(1);
        }

        progress.setLastActivityAt(now);
        progress.setUpdatedAt(now);
        userProgressRepository.save(progress);
    }

    private MasteryLevel calculateMasteryLevel(BigDecimal confidence, int reviewCount) {
        if (reviewCount == 0) return MasteryLevel.NOT_STARTED;
        if (confidence == null) return MasteryLevel.LEARNING;

        double conf = confidence.doubleValue();
        if (conf >= 90 && reviewCount >= 5) return MasteryLevel.MASTERED;
        if (conf >= 75 && reviewCount >= 3) return MasteryLevel.PROFICIENT;
        if (conf >= 50) return MasteryLevel.FAMILIAR;
        return MasteryLevel.LEARNING;
    }

    private Instant calculateNextReviewTime(MasteryLevel level, Instant from) {
        return switch (level) {
            case MASTERED -> from.plus(7, ChronoUnit.DAYS);
            case PROFICIENT -> from.plus(3, ChronoUnit.DAYS);
            case FAMILIAR -> from.plus(1, ChronoUnit.DAYS);
            case LEARNING -> from.plus(4, ChronoUnit.HOURS);
            case NOT_STARTED -> from;
        };
    }

    private UserProgressResponse mapToUserProgressResponse(UserProgress entity) {
        return UserProgressResponse.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .totalNotesViewed(entity.getTotalNotesViewed())
                .totalNotesCompleted(entity.getTotalNotesCompleted())
                .totalMindmapsViewed(entity.getTotalMindmapsViewed())
                .totalMindmapsCompleted(entity.getTotalMindmapsCompleted())
                .totalFlashcardsReviewed(entity.getTotalFlashcardsReviewed())
                .totalQuizzesAttempted(entity.getTotalQuizzesAttempted())
                .averageQuizScore(entity.getAverageQuizScore())
                .totalTimeSpentSeconds(entity.getTotalTimeSpentSeconds())
                .knowledgeScore(entity.getKnowledgeScore())
                .streakDays(entity.getStreakDays())
                .lastActivityAt(entity.getLastActivityAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private ContentProgressResponse mapToContentProgressResponse(ContentProgress entity) {
        return ContentProgressResponse.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .contentId(entity.getContentId())
                .contentType(entity.getContentType())
                .status(entity.getStatus())
                .progressPercent(entity.getProgressPercent())
                .score(entity.getScore())
                .attempts(entity.getAttempts())
                .timeSpentSeconds(entity.getTimeSpentSeconds())
                .lastPosition(entity.getLastPosition())
                .startedAt(entity.getStartedAt())
                .completedAt(entity.getCompletedAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private KnowledgeCoverageResponse mapToKnowledgeCoverageResponse(KnowledgeCoverage entity) {
        return KnowledgeCoverageResponse.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .mindmapId(entity.getMindmapId())
                .nodeId(entity.getNodeId())
                .masteryLevel(entity.getMasteryLevel())
                .confidenceScore(entity.getConfidenceScore())
                .reviewCount(entity.getReviewCount())
                .correctCount(entity.getCorrectCount())
                .lastReviewedAt(entity.getLastReviewedAt())
                .nextReviewAt(entity.getNextReviewAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
