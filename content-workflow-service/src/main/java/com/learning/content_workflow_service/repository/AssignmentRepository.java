package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.Assignment;
import com.learning.content_workflow_service.enums.AssignmentStatus;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface AssignmentRepository extends JpaRepository<Assignment, UUID>, JpaSpecificationExecutor<Assignment> {

    Optional<Assignment> findByIdAndTenantId(UUID id, String tenantId);

    boolean existsByTenantIdAndNoteIdAndClassIdAndStatus(
            String tenantId, UUID noteId, UUID classId, AssignmentStatus status);
}
