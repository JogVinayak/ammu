package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.StudentProfile;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentProfileRepository extends JpaRepository<StudentProfile, UUID> {
    Optional<StudentProfile> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<StudentProfile> findByTenantIdAndClassId(UUID tenantId, UUID classId);

    List<StudentProfile> findByTenantId(UUID tenantId);
}
