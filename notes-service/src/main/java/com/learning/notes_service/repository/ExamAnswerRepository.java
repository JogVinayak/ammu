package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.ExamAnswer;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExamAnswerRepository extends JpaRepository<ExamAnswer, UUID> {

    List<ExamAnswer> findByTenantIdAndExamAttemptIdOrderByAnsweredAtAsc(
            UUID tenantId, UUID examAttemptId);

    boolean existsByTenantIdAndExamAttemptIdAndMcqId(
            UUID tenantId, UUID examAttemptId, UUID mcqId);

    long countByTenantIdAndExamAttemptIdAndCorrectTrue(
            UUID tenantId, UUID examAttemptId);

    long countByTenantIdAndExamAttemptId(UUID tenantId, UUID examAttemptId);
}
