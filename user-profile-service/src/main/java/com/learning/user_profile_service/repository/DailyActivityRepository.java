package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.DailyActivity;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DailyActivityRepository extends JpaRepository<DailyActivity, UUID> {

    Optional<DailyActivity> findByTenantIdAndUserIdAndActivityDate(
            UUID tenantId, UUID userId, LocalDate activityDate);

    List<DailyActivity> findByTenantIdAndUserIdAndActivityDateBetweenOrderByActivityDateAsc(
            UUID tenantId, UUID userId, LocalDate from, LocalDate to);

    List<DailyActivity> findByTenantIdAndUserIdAndActivityDateBetweenOrderByActivityDateDesc(
            UUID tenantId, UUID userId, LocalDate from, LocalDate to);
}
