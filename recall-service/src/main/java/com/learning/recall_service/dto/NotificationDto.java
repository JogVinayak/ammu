package com.learning.recall_service.dto;

import com.learning.recall_service.entity.Notification;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class NotificationDto {
    UUID id;
    String type;
    String title;
    String message;
    UUID referenceId;
    String referenceType;
    boolean read;
    Instant readAt;
    Instant createdAt;

    public static NotificationDto from(Notification entity) {
        return NotificationDto.builder()
                .id(entity.getId())
                .type(entity.getType().name())
                .title(entity.getTitle())
                .message(entity.getMessage())
                .referenceId(entity.getReferenceId())
                .referenceType(entity.getReferenceType())
                .read(entity.isRead())
                .readAt(entity.getReadAt())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
