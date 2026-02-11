package com.learning.content_workflow_service.entity;

import com.learning.content_workflow_service.enums.AssignmentStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "assignments",
        indexes = {
            @Index(name = "idx_assignment_tenant_class", columnList = "tenant_id,class_id"),
            @Index(name = "idx_assignment_tenant_teacher", columnList = "tenant_id,teacher_id"),
            @Index(name = "idx_assignment_tenant_status", columnList = "tenant_id,status"),
            @Index(name = "idx_assignment_tenant_note", columnList = "tenant_id,note_id")
        })
@Getter
@Setter
@NoArgsConstructor
public class Assignment {

    @Id
    @Column(name = "assignment_id")
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "note_id", nullable = false)
    private UUID noteId;

    @Column(name = "class_id", nullable = false)
    private UUID classId;

    @Column(name = "teacher_id", nullable = false)
    private String teacherId;

    @Column(name = "title", length = 200)
    private String title;

    @Column(name = "description", length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private AssignmentStatus status;

    @Column(name = "due_date")
    private Instant dueDate;

    @Lob
    @Column(name = "cycle_config_json")
    private String cycleConfigJson;

    @Column(name = "student_count")
    private Integer studentCount;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Version
    @Column(name = "lock_version")
    private Long version;
}
