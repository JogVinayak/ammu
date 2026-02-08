package com.learning.user_profile_service.model.entity;

import com.learning.user_profile_service.model.enums.ContentType;
import com.learning.user_profile_service.model.enums.ProgressEventType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "progress_events")
@Getter
@Setter
@NoArgsConstructor
public class ProgressEvent {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false)
    private ProgressEventType eventType;

    @Column(name = "content_id")
    private UUID contentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "content_type")
    private ContentType contentType;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "event_data", columnDefinition = "jsonb")
    private String eventData;

    @Column(name = "created_at")
    private Instant createdAt;
}
