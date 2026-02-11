package com.learning.tenant_service.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "teacher_class_assignments")
@Getter
@Setter
@NoArgsConstructor
public class TeacherClassAssignment {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "class_id", nullable = false)
    private UUID classId;

    @Column(name = "teacher_id", nullable = false)
    private UUID teacherId;

    @Column(name = "role", nullable = false, length = 32)
    private String role;

    @Column(name = "subject", length = 100)
    private String subject;

    @Column(name = "assigned_at")
    private Instant assignedAt;

    @Column(name = "assigned_by")
    private String assignedBy;
}
