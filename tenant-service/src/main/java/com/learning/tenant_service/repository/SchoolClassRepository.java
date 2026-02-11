package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.SchoolClass;
import com.learning.tenant_service.model.enums.SchoolClassStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SchoolClassRepository extends JpaRepository<SchoolClass, UUID> {
    List<SchoolClass> findByTenantIdAndStatus(UUID tenantId, SchoolClassStatus status);

    List<SchoolClass> findByTenantId(UUID tenantId);

    Optional<SchoolClass> findByIdAndTenantId(UUID id, UUID tenantId);

    boolean existsByTenantIdAndGradeLevel(UUID tenantId, Integer gradeLevel);
}
