package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.ReviewTask;
import com.learning.content_workflow_service.enums.ReviewTaskStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewTaskRepository extends JpaRepository<ReviewTask, UUID> {
    List<ReviewTask> findByWorkflowId(UUID workflowId);

    Optional<ReviewTask> findByIdAndWorkflowId(UUID id, UUID workflowId);

    long countByWorkflowIdAndStatus(UUID workflowId, ReviewTaskStatus status);

    void deleteByWorkflowId(UUID workflowId);
}
