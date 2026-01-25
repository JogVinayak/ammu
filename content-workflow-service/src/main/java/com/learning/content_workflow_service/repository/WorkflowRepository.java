package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.Workflow;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface WorkflowRepository extends JpaRepository<Workflow, UUID>, JpaSpecificationExecutor<Workflow> {
    Optional<Workflow> findByIdAndTenantId(UUID id, String tenantId);

    boolean existsByTenantIdAndContentIdAndContentVersionId(
            String tenantId,
            String contentId,
            String contentVersionId);
}
