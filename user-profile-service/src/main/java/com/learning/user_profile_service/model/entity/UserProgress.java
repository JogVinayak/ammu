package com.learning.user_profile_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "user_progress")
@Getter
@Setter
@NoArgsConstructor
public class UserProgress {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "total_notes_viewed")
    private Integer totalNotesViewed = 0;

    @Column(name = "total_notes_completed")
    private Integer totalNotesCompleted = 0;

    @Column(name = "total_mindmaps_viewed")
    private Integer totalMindmapsViewed = 0;

    @Column(name = "total_mindmaps_completed")
    private Integer totalMindmapsCompleted = 0;

    @Column(name = "total_flashcards_reviewed")
    private Integer totalFlashcardsReviewed = 0;

    @Column(name = "total_quizzes_attempted")
    private Integer totalQuizzesAttempted = 0;

    @Column(name = "average_quiz_score", precision = 5, scale = 2)
    private BigDecimal averageQuizScore;

    @Column(name = "total_time_spent_seconds")
    private Long totalTimeSpentSeconds = 0L;

    @Column(name = "knowledge_score", precision = 5, scale = 2)
    private BigDecimal knowledgeScore;

    @Column(name = "streak_days")
    private Integer streakDays = 0;

    @Column(name = "last_activity_at")
    private Instant lastActivityAt;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
