package com.learning.content_workflow_service.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "school_classes",
        indexes = {
            @Index(name = "idx_class_tenant", columnList = "tenant_id"),
            @Index(name = "idx_class_tenant_grade", columnList = "tenant_id,grade"),
            @Index(name = "idx_class_tenant_subject", columnList = "tenant_id,subject")
        })
@Getter
@Setter
@NoArgsConstructor
public class SchoolClass {
    @Id
    @Column(name = "class_id")
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "subject", length = 100)
    private String subject;

    @Column(name = "grade", length = 50)
    private String grade;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "student_count")
    private Integer studentCount = 0;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_by")
    private String updatedBy;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Version
    @Column(name = "lock_version")
    private Long version;
}
