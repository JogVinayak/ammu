package com.learning.content_service.dto;

import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import com.learning.content_service.enums.ContentVisibility;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ContentResponse {
    private UUID id;
    private String tenantId;
    private ContentType type;
    private String title;
    private String description;
    private ContentStatus status;
    private Integer currentVersion;
    private Integer latestDraftVersion;
    private ContentVisibility visibility;
    private UUID topicId;
    private UUID moduleId;
    private List<String> tags;
    private Instant createdAt;
    private Instant updatedAt;
}
