package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.SchoolClass;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SchoolClassRepository extends JpaRepository<SchoolClass, UUID> {
    Optional<SchoolClass> findByIdAndTenantId(UUID id, String tenantId);

    Page<SchoolClass> findByTenantId(String tenantId, Pageable pageable);

    List<SchoolClass> findByTenantId(String tenantId);

    Page<SchoolClass> findByTenantIdAndGrade(String tenantId, String grade, Pageable pageable);

    Page<SchoolClass> findByTenantIdAndSubject(String tenantId, String subject, Pageable pageable);

    boolean existsByIdAndTenantId(UUID id, String tenantId);

    List<SchoolClass> findByTenantIdAndIdIn(String tenantId, List<UUID> ids);
}
