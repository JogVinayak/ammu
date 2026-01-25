package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.ChangeRequest;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChangeRequestRepository extends JpaRepository<ChangeRequest, UUID> {
    List<ChangeRequest> findByWorkflowId(UUID workflowId);
}
