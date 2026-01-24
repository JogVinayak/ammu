package com.learning.content_service.service;

import com.learning.content_service.dto.ContentListResponse;
import com.learning.content_service.dto.ContentResponse;
import com.learning.content_service.dto.ContentStatusChangeRequest;
import com.learning.content_service.dto.CreateContentRequest;
import com.learning.content_service.dto.UpdateContentRequest;
import com.learning.content_service.dto.VersionBumpRequest;
import com.learning.content_service.dto.VersionBumpResponse;
import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import java.util.UUID;

public interface ContentService {
    ContentResponse create(CreateContentRequest request);

    ContentResponse getById(UUID id);

    ContentListResponse list(
            ContentType type,
            ContentStatus status,
            UUID topicId,
            UUID moduleId,
            String query,
            int page,
            int size,
            String sort);

    ContentResponse update(UUID id, UpdateContentRequest request);

    ContentResponse changeStatus(UUID id, ContentStatusChangeRequest request);

    VersionBumpResponse bumpVersion(UUID id, VersionBumpRequest request);

    void softDelete(UUID id);
}
