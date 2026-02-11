package com.learning.content_workflow_service.entity;

import com.learning.content_workflow_service.enums.StudentAssignmentStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "student_assignments",
        indexes = {
            @Index(name = "idx_student_assign_assignment", columnList = "assignment_id"),
            @Index(name = "idx_student_assign_student", columnList = "tenant_id,student_id"),
            @Index(name = "idx_student_assign_status", columnList = "assignment_id,status")
        })
@Getter
@Setter
@NoArgsConstructor
public class StudentAssignment {

    @Id
    @Column(name = "student_assignment_id")
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "assignment_id", nullable = false)
    private UUID assignmentId;

    @Column(name = "student_id", nullable = false)
    private String studentId;

    @Column(name = "student_name", length = 200)
    private String studentName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private StudentAssignmentStatus status;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "recall_schedule_id")
    private UUID recallScheduleId;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
