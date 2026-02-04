package com.learning.content_workflow_service.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class ReleasedContentResponse {
    private UUID id;
    private UUID contentId;
    private String contentType;
    private UUID classId;
    private UUID releasedBy;
    private Instant releasedAt;
}
