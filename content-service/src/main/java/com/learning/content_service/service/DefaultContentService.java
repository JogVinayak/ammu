package com.learning.content_service.service;

import com.learning.content_service.dto.ContentListResponse;
import com.learning.content_service.dto.ContentResponse;
import com.learning.content_service.dto.ContentStatusChangeRequest;
import com.learning.content_service.dto.CreateContentRequest;
import com.learning.content_service.dto.UpdateContentRequest;
import com.learning.content_service.dto.VersionBumpRequest;
import com.learning.content_service.dto.VersionBumpResponse;
import com.learning.content_service.entity.Content;
import com.learning.content_service.entity.ContentTag;
import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import com.learning.content_service.enums.ContentVisibility;
import com.learning.content_service.enums.VersionBumpKind;
import com.learning.content_service.exception.BadRequestException;
import com.learning.content_service.exception.ConflictException;
import com.learning.content_service.exception.ForbiddenException;
import com.learning.content_service.exception.NotFoundException;
import com.learning.content_service.repository.ContentRepository;
import com.learning.content_service.repository.ContentTagRepository;
import com.learning.content_service.util.AccessGuard;
import com.learning.content_service.util.TenantContext;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DefaultContentService implements ContentService {
    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> ALLOWED_SORT_FIELDS =
            Set.of("createdAt", "updatedAt", "title", "status", "type");

    private final ContentRepository contentRepository;
    private final ContentTagRepository contentTagRepository;
    private final OutboxService outboxService;
    private final AccessGuard accessGuard;

    @Override
    @Transactional
    public ContentResponse create(CreateContentRequest request) {
        TenantContext context = accessGuard.requireWrite();
        Content content = new Content();
        content.setId(UUID.randomUUID());
        content.setTenantId(context.getTenantId());
        content.setType(request.getType());
        content.setTitle(request.getTitle().trim());
        content.setDescription(trimToNull(request.getDescription()));
        content.setStatus(ContentStatus.DRAFT);
        content.setCurrentVersion(1);
        content.setLatestDraftVersion(1);
        content.setVisibility(resolveVisibility(request.getVisibility()));
        content.setTopicId(request.getTopicId());
        content.setModuleId(request.getModuleId());
        content.setCreatedBy(context.getUserId());
        content.setUpdatedBy(context.getUserId());
        Instant now = Instant.now();
        content.setCreatedAt(now);
        content.setUpdatedAt(now);
        content.setDeleted(false);

        contentRepository.save(content);
        List<String> tags = persistTags(context.getTenantId(), content.getId(), request.getTags());

        outboxService.recordContentEvent(content, "CONTENT_CREATED");
        return toResponse(content, tags);
    }

    @Override
    @Transactional(readOnly = true)
    public ContentResponse getById(UUID id) {
        AccessGuard.ReadAccess access = accessGuard.requireRead();
        TenantContext context = access.getContext();
        Content content = contentRepository.findByIdAndTenantIdAndDeletedFalse(id, context.getTenantId())
                .orElseThrow(() -> new NotFoundException("Content not found"));
        if (access.isRestrictToTenantVisibility() && content.getVisibility() != ContentVisibility.TENANT) {
            throw new ForbiddenException("Content not visible for role");
        }
        List<String> tags = loadTagsForContent(context.getTenantId(), content.getId());
        return toResponse(content, tags);
    }

    @Override
    @Transactional(readOnly = true)
    public ContentListResponse list(
            ContentType type,
            ContentStatus status,
            UUID topicId,
            UUID moduleId,
            String query,
            int page,
            int size,
            String sort) {
        AccessGuard.ReadAccess access = accessGuard.requireRead();
        TenantContext context = access.getContext();
        ContentVisibility visibilityFilter = access.isRestrictToTenantVisibility() ? ContentVisibility.TENANT : null;

        PageRequest pageRequest = PageRequest.of(
                normalizePage(page),
                normalizeSize(size),
                parseSort(sort));

        Page<Content> results = contentRepository.search(
                context.getTenantId(),
                type,
                status,
                topicId,
                moduleId,
                visibilityFilter,
                normalizeQuery(query),
                pageRequest);

        List<Content> contents = results.getContent();
        Map<UUID, List<String>> tagsByContentId = loadTagsForContents(context.getTenantId(), contents);

        List<ContentResponse> items = contents.stream()
                .map(content -> toResponse(content, tagsByContentId.getOrDefault(content.getId(), List.of())))
                .collect(Collectors.toList());

        ContentListResponse response = new ContentListResponse();
        response.setItems(items);
        response.setPage(results.getNumber());
        response.setSize(results.getSize());
        response.setTotal(results.getTotalElements());
        return response;
    }

    @Override
    @Transactional
    public ContentResponse update(UUID id, UpdateContentRequest request) {
        TenantContext context = accessGuard.requireWrite();
        Content content = loadContentForWrite(id, context.getTenantId());

        if (request.getTitle() != null) {
            String trimmedTitle = request.getTitle().trim();
            if (trimmedTitle.isEmpty()) {
                throw new BadRequestException("title must not be blank");
            }
            content.setTitle(trimmedTitle);
        }
        if (request.getDescription() != null) {
            content.setDescription(trimToNull(request.getDescription()));
        }
        if (request.getVisibility() != null) {
            content.setVisibility(request.getVisibility());
        }
        if (request.getTopicId() != null) {
            content.setTopicId(request.getTopicId());
        }
        if (request.getModuleId() != null) {
            content.setModuleId(request.getModuleId());
        }

        List<String> tags;
        if (request.getTags() != null) {
            tags = replaceTags(context.getTenantId(), content.getId(), request.getTags());
        } else {
            tags = loadTagsForContent(context.getTenantId(), content.getId());
        }

        content.setUpdatedBy(context.getUserId());
        content.setUpdatedAt(Instant.now());
        contentRepository.save(content);

        outboxService.recordContentEvent(content, "CONTENT_UPDATED");
        return toResponse(content, tags);
    }

    @Override
    @Transactional
    public ContentResponse changeStatus(UUID id, ContentStatusChangeRequest request) {
        TenantContext context = accessGuard.requireWrite();
        Content content = loadContentForWrite(id, context.getTenantId());

        ContentStatus currentStatus = content.getStatus();
        ContentStatus targetStatus = request.getStatus();
        if (!isValidTransition(currentStatus, targetStatus)) {
            throw new ConflictException("Invalid status transition");
        }

        content.setStatus(targetStatus);
        content.setUpdatedBy(context.getUserId());
        content.setUpdatedAt(Instant.now());
        contentRepository.save(content);

        outboxService.recordContentEvent(content, "CONTENT_STATUS_CHANGED");
        List<String> tags = loadTagsForContent(context.getTenantId(), content.getId());
        return toResponse(content, tags);
    }

    @Override
    @Transactional
    public VersionBumpResponse bumpVersion(UUID id, VersionBumpRequest request) {
        TenantContext context = accessGuard.requireWrite();
        Content content = loadContentForWrite(id, context.getTenantId());

        VersionBumpKind kind = request.getKind();
        if (kind == VersionBumpKind.DRAFT) {
            Integer latestDraft = content.getLatestDraftVersion();
            if (latestDraft == null) {
                content.setLatestDraftVersion(content.getCurrentVersion() + 1);
            } else {
                content.setLatestDraftVersion(latestDraft + 1);
            }
        } else if (kind == VersionBumpKind.PUBLISHED) {
            Integer latestDraft = content.getLatestDraftVersion();
            if (latestDraft != null) {
                content.setCurrentVersion(latestDraft);
            } else {
                content.setCurrentVersion(content.getCurrentVersion() + 1);
                content.setLatestDraftVersion(content.getCurrentVersion());
            }
        }

        content.setUpdatedBy(context.getUserId());
        content.setUpdatedAt(Instant.now());
        contentRepository.save(content);

        outboxService.recordContentEvent(content, "CONTENT_UPDATED");

        VersionBumpResponse response = new VersionBumpResponse();
        response.setContentId(content.getId());
        response.setCurrentVersion(content.getCurrentVersion());
        response.setLatestDraftVersion(content.getLatestDraftVersion());
        return response;
    }

    @Override
    @Transactional
    public void softDelete(UUID id) {
        TenantContext context = accessGuard.requireWrite();
        Content content = contentRepository.findByIdAndTenantIdAndDeletedFalse(id, context.getTenantId())
                .orElseThrow(() -> new NotFoundException("Content not found"));
        content.setDeleted(true);
        content.setStatus(ContentStatus.ARCHIVED);
        content.setUpdatedBy(context.getUserId());
        content.setUpdatedAt(Instant.now());
        contentRepository.save(content);

        outboxService.recordContentEvent(content, "CONTENT_DELETED");
    }

    private Content loadContentForWrite(UUID id, String tenantId) {
        Content content = contentRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> new NotFoundException("Content not found"));
        if (content.isDeleted()) {
            throw new NotFoundException("Content not found");
        }
        return content;
    }

    private List<String> persistTags(String tenantId, UUID contentId, List<String> tags) {
        List<String> normalized = normalizeTags(tags);
        if (normalized.isEmpty()) {
            return List.of();
        }
        List<ContentTag> entities = normalized.stream()
                .map(tag -> buildTagEntity(tenantId, contentId, tag))
                .collect(Collectors.toList());
        contentTagRepository.saveAll(entities);
        return normalized;
    }

    private List<String> replaceTags(String tenantId, UUID contentId, List<String> tags) {
        contentTagRepository.deleteByTenantIdAndContentId(tenantId, contentId);
        return persistTags(tenantId, contentId, tags);
    }

    private List<String> loadTagsForContent(String tenantId, UUID contentId) {
        return contentTagRepository.findByTenantIdAndContentId(tenantId, contentId).stream()
                .map(ContentTag::getTag)
                .sorted()
                .collect(Collectors.toList());
    }

    private Map<UUID, List<String>> loadTagsForContents(String tenantId, List<Content> contents) {
        if (contents.isEmpty()) {
            return Map.of();
        }
        List<UUID> ids = contents.stream().map(Content::getId).collect(Collectors.toList());
        Map<UUID, List<String>> tagsByContentId = new HashMap<>();
        contentTagRepository.findByTenantIdAndContentIdIn(tenantId, ids).forEach(tag -> {
            tagsByContentId.computeIfAbsent(tag.getContentId(), value -> new ArrayList<>()).add(tag.getTag());
        });
        tagsByContentId.values().forEach(list -> list.sort(Comparator.naturalOrder()));
        return tagsByContentId;
    }

    private ContentResponse toResponse(Content content, List<String> tags) {
        ContentResponse response = new ContentResponse();
        response.setId(content.getId());
        response.setTenantId(content.getTenantId());
        response.setType(content.getType());
        response.setTitle(content.getTitle());
        response.setDescription(content.getDescription());
        response.setStatus(content.getStatus());
        response.setCurrentVersion(content.getCurrentVersion());
        response.setLatestDraftVersion(content.getLatestDraftVersion());
        response.setVisibility(content.getVisibility());
        response.setTopicId(content.getTopicId());
        response.setModuleId(content.getModuleId());
        response.setTags(tags);
        response.setCreatedAt(content.getCreatedAt());
        response.setUpdatedAt(content.getUpdatedAt());
        return response;
    }

    private ContentTag buildTagEntity(String tenantId, UUID contentId, String tag) {
        ContentTag contentTag = new ContentTag();
        contentTag.setId(UUID.randomUUID());
        contentTag.setTenantId(tenantId);
        contentTag.setContentId(contentId);
        contentTag.setTag(tag);
        return contentTag;
    }

    private List<String> normalizeTags(List<String> tags) {
        if (tags == null) {
            return List.of();
        }
        return tags.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .map(value -> value.toLowerCase(Locale.ROOT))
                .distinct()
                .collect(Collectors.toList());
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private ContentVisibility resolveVisibility(ContentVisibility visibility) {
        return visibility == null ? ContentVisibility.PRIVATE : visibility;
    }

    private boolean isValidTransition(ContentStatus current, ContentStatus target) {
        if (current == null || target == null) {
            return false;
        }
        if (current == ContentStatus.DRAFT && target == ContentStatus.PUBLISHED) {
            return true;
        }
        if (current == ContentStatus.DRAFT && target == ContentStatus.ARCHIVED) {
            return true;
        }
        return current == ContentStatus.PUBLISHED && target == ContentStatus.ARCHIVED;
    }

    private int normalizePage(int page) {
        return Math.max(page, 0);
    }

    private int normalizeSize(int size) {
        if (size <= 0) {
            return DEFAULT_PAGE_SIZE;
        }
        return Math.min(size, MAX_PAGE_SIZE);
    }

    private Sort parseSort(String sortParam) {
        String sortValue = sortParam == null || sortParam.isBlank() ? "updatedAt,desc" : sortParam;
        String[] parts = sortValue.split(",");
        String field = parts[0].trim();
        if (!ALLOWED_SORT_FIELDS.contains(field)) {
            field = "updatedAt";
        }
        Sort.Direction direction = Sort.Direction.DESC;
        if (parts.length > 1 && "asc".equalsIgnoreCase(parts[1].trim())) {
            direction = Sort.Direction.ASC;
        }
        return Sort.by(direction, field);
    }

    private String normalizeQuery(String query) {
        if (query == null) {
            return null;
        }
        String trimmed = query.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
