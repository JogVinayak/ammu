package com.learning.recall_service.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;
import lombok.Data;

@Data
public class CreateNotificationRequest {
    @NotNull
    private List<UUID> userIds;

    @NotBlank
    private String type;

    @NotBlank
    private String title;

    @NotBlank
    private String message;

    private UUID referenceId;
    private String referenceType;
}
