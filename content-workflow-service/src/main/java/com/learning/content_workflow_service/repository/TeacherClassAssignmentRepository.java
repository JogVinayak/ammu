package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.TeacherClassAssignment;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface TeacherClassAssignmentRepository extends JpaRepository<TeacherClassAssignment, UUID> {
    List<TeacherClassAssignment> findByTenantIdAndTeacherId(String tenantId, UUID teacherId);

    @Query("SELECT tca.classId FROM TeacherClassAssignment tca WHERE tca.tenantId = :tenantId AND tca.teacherId = :teacherId")
    List<UUID> findClassIdsByTenantIdAndTeacherId(@Param("tenantId") String tenantId, @Param("teacherId") UUID teacherId);
}
