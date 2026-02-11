package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.ConceptProgressResponse;
import com.learning.user_profile_service.model.dto.RecordExamResultRequest;
import com.learning.user_profile_service.model.dto.RecordFlashcardReviewRequest;
import com.learning.user_profile_service.model.dto.RecordReadingSessionRequest;
import com.learning.user_profile_service.model.entity.StudentConceptProgress;
import com.learning.user_profile_service.model.enums.ActivityRingType;
import com.learning.user_profile_service.model.enums.ConceptMasteryState;
import com.learning.user_profile_service.repository.StudentConceptProgressRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultConceptProgressService implements ConceptProgressService {

    private static final int PASS_THRESHOLD = 80;
    private static final long MAINTENANCE_DAYS = 7;

    private final StudentConceptProgressRepository repository;
    private final ActivityRingService activityRingService;

    @Override
    @Transactional
    public ConceptProgressResponse recordExamResult(UUID tenantId, UUID userId,
                                                     RecordExamResultRequest request) {
        StudentConceptProgress progress = findOrCreate(tenantId, userId, request.getNoteId());
        Instant now = Instant.now();

        // First engagement transitions INITIAL → LEARNING
        if (progress.getMasteryState() == ConceptMasteryState.INITIAL) {
            progress.setMasteryState(ConceptMasteryState.LEARNING);
        }

        progress.setTotalExamAttempts(progress.getTotalExamAttempts() + 1);
        progress.setLastExamScore(request.getScore());
        progress.setLastReviewedAt(now);
        progress.setUpdatedAt(now);

        if (request.getPassed()) {
            progress.setPassedExamCount(progress.getPassedExamCount() + 1);
            progress.setLastExamPassedAt(now);

            // Increase memory strength: score 80→×1.0, 90→×1.1, 100→×1.2
            double factor = 1.0 + (request.getScore() - PASS_THRESHOLD) / 100.0;
            progress.setMemoryStrength(progress.getMemoryStrength() * Math.max(1.0, factor));

            // State transitions on pass
            switch (progress.getMasteryState()) {
                case LEARNING:
                    progress.setMasteryState(ConceptMasteryState.MASTERY);
                    progress.setMasteryAchievedAt(now);
                    break;
                case MASTERY:
                    // Check if 7+ days since mastery achieved
                    if (progress.getMasteryAchievedAt() != null
                            && ChronoUnit.DAYS.between(progress.getMasteryAchievedAt(), now) >= MAINTENANCE_DAYS) {
                        progress.setMasteryState(ConceptMasteryState.MAINTENANCE);
                    }
                    break;
                case REVOKED:
                    progress.setMasteryState(ConceptMasteryState.LEARNING);
                    break;
                case MAINTENANCE:
                    // Stay in MAINTENANCE
                    break;
                default:
                    break;
            }
        } else {
            // Failed exam: decrease memory strength (floor at 1.0)
            progress.setMemoryStrength(Math.max(1.0, progress.getMemoryStrength() * 0.5));

            // Revoke mastery if currently in MASTERY or MAINTENANCE
            if (progress.getMasteryState() == ConceptMasteryState.MASTERY
                    || progress.getMasteryState() == ConceptMasteryState.MAINTENANCE) {
                progress.setMasteryState(ConceptMasteryState.REVOKED);
                progress.setMasteryAchievedAt(null);
            }
        }

        repository.save(progress);
        activityRingService.recordActivity(tenantId, userId, ActivityRingType.EXAM);
        return toResponse(progress);
    }

    @Override
    @Transactional
    public ConceptProgressResponse recordFlashcardReview(UUID tenantId, UUID userId,
                                                          RecordFlashcardReviewRequest request) {
        StudentConceptProgress progress = findOrCreate(tenantId, userId, request.getNoteId());
        Instant now = Instant.now();

        if (progress.getMasteryState() == ConceptMasteryState.INITIAL) {
            progress.setMasteryState(ConceptMasteryState.LEARNING);
        }

        progress.setTotalFlashcardsReviewed(progress.getTotalFlashcardsReviewed() + 1);
        progress.setLastReviewedAt(now);
        progress.setUpdatedAt(now);

        repository.save(progress);
        activityRingService.recordActivity(tenantId, userId, ActivityRingType.FLASHCARD);
        return toResponse(progress);
    }

    @Override
    @Transactional
    public ConceptProgressResponse recordReadingSession(UUID tenantId, UUID userId,
                                                         RecordReadingSessionRequest request) {
        StudentConceptProgress progress = findOrCreate(tenantId, userId, request.getNoteId());
        Instant now = Instant.now();

        if (progress.getMasteryState() == ConceptMasteryState.INITIAL) {
            progress.setMasteryState(ConceptMasteryState.LEARNING);
        }

        progress.setTotalReadingSessions(progress.getTotalReadingSessions() + 1);
        progress.setLastReviewedAt(now);
        progress.setUpdatedAt(now);

        repository.save(progress);
        activityRingService.recordActivity(tenantId, userId, ActivityRingType.READING);
        return toResponse(progress);
    }

    @Override
    @Transactional(readOnly = true)
    public ConceptProgressResponse getConceptProgress(UUID tenantId, UUID userId, UUID noteId) {
        StudentConceptProgress progress = repository
                .findByTenantIdAndUserIdAndNoteId(tenantId, userId, noteId)
                .orElseThrow(() -> new RuntimeException("Concept progress not found"));
        return toResponse(progress);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ConceptProgressResponse> listConceptProgress(UUID tenantId, UUID userId) {
        return repository.findByTenantIdAndUserId(tenantId, userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Double getRetention(UUID tenantId, UUID userId, UUID noteId) {
        StudentConceptProgress progress = repository
                .findByTenantIdAndUserIdAndNoteId(tenantId, userId, noteId)
                .orElseThrow(() -> new RuntimeException("Concept progress not found"));
        return calculateRetention(progress);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ConceptProgressResponse> listDecayingConcepts(UUID tenantId, UUID userId,
                                                               double threshold) {
        return repository.findByTenantIdAndUserId(tenantId, userId)
                .stream()
                .filter(p -> p.getLastReviewedAt() != null)
                .filter(p -> calculateRetention(p) < threshold)
                .sorted(Comparator.comparingDouble(this::calculateRetention))
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private StudentConceptProgress findOrCreate(UUID tenantId, UUID userId, UUID noteId) {
        return repository.findByTenantIdAndUserIdAndNoteId(tenantId, userId, noteId)
                .orElseGet(() -> {
                    Instant now = Instant.now();
                    StudentConceptProgress p = new StudentConceptProgress();
                    p.setId(UUID.randomUUID());
                    p.setTenantId(tenantId);
                    p.setUserId(userId);
                    p.setNoteId(noteId);
                    p.setMasteryState(ConceptMasteryState.INITIAL);
                    p.setMemoryStrength(1.0);
                    p.setTotalExamAttempts(0);
                    p.setPassedExamCount(0);
                    p.setTotalFlashcardsReviewed(0);
                    p.setTotalReadingSessions(0);
                    p.setCreatedAt(now);
                    p.setUpdatedAt(now);
                    return p;
                });
    }

    private double calculateRetention(StudentConceptProgress progress) {
        if (progress.getLastReviewedAt() == null) {
            return 0.0;
        }
        double t = Duration.between(progress.getLastReviewedAt(), Instant.now())
                .toSeconds() / 86400.0; // Convert to fractional days
        double s = progress.getMemoryStrength();
        return Math.exp(-t / s); // R = e^(-t/S)
    }

    private ConceptProgressResponse toResponse(StudentConceptProgress progress) {
        return ConceptProgressResponse.builder()
                .id(progress.getId())
                .userId(progress.getUserId())
                .noteId(progress.getNoteId())
                .masteryState(progress.getMasteryState())
                .memoryStrength(progress.getMemoryStrength())
                .retention(calculateRetention(progress))
                .lastExamScore(progress.getLastExamScore())
                .lastExamPassedAt(progress.getLastExamPassedAt())
                .totalExamAttempts(progress.getTotalExamAttempts())
                .passedExamCount(progress.getPassedExamCount())
                .totalFlashcardsReviewed(progress.getTotalFlashcardsReviewed())
                .totalReadingSessions(progress.getTotalReadingSessions())
                .lastReviewedAt(progress.getLastReviewedAt())
                .masteryAchievedAt(progress.getMasteryAchievedAt())
                .createdAt(progress.getCreatedAt())
                .updatedAt(progress.getUpdatedAt())
                .build();
    }
}
