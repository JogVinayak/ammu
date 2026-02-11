package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.ExamAttempt;
import com.learning.notes_service.model.enums.ExamAttemptStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExamAttemptRepository extends JpaRepository<ExamAttempt, UUID> {

    Optional<ExamAttempt> findByIdAndTenantId(UUID id, UUID tenantId);

    List<ExamAttempt> findByTenantIdAndNoteIdAndStudentIdOrderByCreatedAtDesc(
            UUID tenantId, UUID noteId, UUID studentId);

    List<ExamAttempt> findByTenantIdAndNoteIdAndStudentIdAndStatus(
            UUID tenantId, UUID noteId, UUID studentId, ExamAttemptStatus status);

    @Query("SELECT COUNT(a) FROM ExamAttempt a WHERE a.tenantId = :tenantId "
           + "AND a.noteId = :noteId AND a.studentId = :studentId "
           + "AND a.status = com.learning.notes_service.model.enums.ExamAttemptStatus.COMPLETED")
    long countCompletedAttempts(@Param("tenantId") UUID tenantId,
                                @Param("noteId") UUID noteId,
                                @Param("studentId") UUID studentId);

    @Query("SELECT MAX(a.scorePercent) FROM ExamAttempt a WHERE a.tenantId = :tenantId "
           + "AND a.noteId = :noteId AND a.studentId = :studentId "
           + "AND a.status = com.learning.notes_service.model.enums.ExamAttemptStatus.COMPLETED")
    Integer findBestScore(@Param("tenantId") UUID tenantId,
                          @Param("noteId") UUID noteId,
                          @Param("studentId") UUID studentId);

    @Query("SELECT AVG(a.scorePercent) FROM ExamAttempt a WHERE a.tenantId = :tenantId "
           + "AND a.noteId = :noteId AND a.studentId = :studentId "
           + "AND a.status = com.learning.notes_service.model.enums.ExamAttemptStatus.COMPLETED")
    Double findAverageScore(@Param("tenantId") UUID tenantId,
                            @Param("noteId") UUID noteId,
                            @Param("studentId") UUID studentId);

    @Query("SELECT COUNT(a) FROM ExamAttempt a WHERE a.tenantId = :tenantId "
           + "AND a.noteId = :noteId AND a.studentId = :studentId "
           + "AND a.status = com.learning.notes_service.model.enums.ExamAttemptStatus.COMPLETED "
           + "AND a.passed = true")
    long countPassedAttempts(@Param("tenantId") UUID tenantId,
                             @Param("noteId") UUID noteId,
                             @Param("studentId") UUID studentId);
}
