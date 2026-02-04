package com.learning.recall_service.repository;

import com.learning.recall_service.entity.RecallSchedule;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RecallScheduleRepository extends JpaRepository<RecallSchedule, UUID> {
    Optional<RecallSchedule> findByTenantIdAndUserIdAndTopicId(UUID tenantId, UUID userId, UUID topicId);

    @Query("""
            select s from RecallSchedule s
            where s.tenantId = :tenantId
              and s.userId = :userId
              and s.nextReviewAt <= :asOf
            order by s.nextReviewAt asc
            """)
    List<RecallSchedule> findDueForUser(
            @Param("tenantId") UUID tenantId,
            @Param("userId") UUID userId,
            @Param("asOf") Instant asOf,
            Pageable pageable);

    @Query("""
            select s from RecallSchedule s
            where s.nextReviewAt <= :asOf
              and (s.lastNotifiedAt is null or s.lastNotifiedAt <= :minNotifiedAt)
            order by s.nextReviewAt asc
            """)
    List<RecallSchedule> findDueForReminder(
            @Param("asOf") Instant asOf,
            @Param("minNotifiedAt") Instant minNotifiedAt,
            Pageable pageable);
}
