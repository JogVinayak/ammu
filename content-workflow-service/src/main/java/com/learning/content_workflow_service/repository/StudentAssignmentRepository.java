package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.StudentAssignment;
import com.learning.content_workflow_service.enums.StudentAssignmentStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentAssignmentRepository extends JpaRepository<StudentAssignment, UUID> {

    List<StudentAssignment> findByAssignmentId(UUID assignmentId);

    Page<StudentAssignment> findByTenantIdAndStudentId(String tenantId, String studentId, Pageable pageable);

    long countByAssignmentIdAndStatus(UUID assignmentId, StudentAssignmentStatus status);

    void deleteByAssignmentId(UUID assignmentId);
}
