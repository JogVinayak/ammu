package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.dto.CreateWorkflowRequest;
import com.learning.content_workflow_service.dto.PublishTargets;
import com.learning.content_workflow_service.dto.PublishWorkflowRequest;
import com.learning.content_workflow_service.dto.ReleaseContentRequest;
import com.learning.content_workflow_service.dto.ReleasedContentResponse;
import com.learning.content_workflow_service.dto.ReviewActionRequest;
import com.learning.content_workflow_service.dto.ReviewTaskDto;
import com.learning.content_workflow_service.dto.SubmitForReviewRequest;
import com.learning.content_workflow_service.dto.WorkflowListResponse;
import com.learning.content_workflow_service.dto.WorkflowResponse;
import com.learning.content_workflow_service.entity.ReleasedContent;
import com.learning.content_workflow_service.entity.ReviewTask;
import com.learning.content_workflow_service.entity.Workflow;
import com.learning.content_workflow_service.enums.ReviewTaskStatus;
import com.learning.content_workflow_service.enums.WorkflowState;
import com.learning.content_workflow_service.exception.BadRequestException;
import com.learning.content_workflow_service.exception.ConflictException;
import com.learning.content_workflow_service.exception.NotFoundException;
import com.learning.content_workflow_service.repository.ReleasedContentRepository;
import com.learning.content_workflow_service.repository.ReviewTaskRepository;
import com.learning.content_workflow_service.repository.WorkflowRepository;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
public class DefaultWorkflowService implements WorkflowService {
    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 100;

    private final WorkflowRepository workflowRepository;
    private final ReviewTaskRepository reviewTaskRepository;
    private final ReleasedContentRepository releasedContentRepository;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public WorkflowResponse createWorkflow(String tenantId, String userId, CreateWorkflowRequest request) {
        String contentId = request.getContentId().trim();
        String contentVersionId = request.getContentVersionId().trim();
        if (workflowRepository.existsByTenantIdAndContentIdAndContentVersionId(
                tenantId,
                contentId,
                contentVersionId)) {
            throw new ConflictException("Workflow already exists for this content version");
        }

        Instant now = Instant.now();
        Workflow workflow = new Workflow();
        workflow.setId(UUID.randomUUID());
        workflow.setTenantId(tenantId);
        workflow.setContentId(contentId);
        workflow.setContentVersionId(contentVersionId);
        workflow.setTitleSnapshot(trimToNull(request.getTitleSnapshot()));
        workflow.setState(WorkflowState.DRAFT);
        workflow.setRequiredApprovals(null);
        String actor = resolveActor(userId);
        workflow.setCreatedBy(actor);
        workflow.setCreatedAt(now);
        workflow.setLastUpdatedBy(actor);
        workflow.setLastUpdatedAt(now);
        workflow.setCurrentStep(null);
        workflow.setPublishTargetsJson(serializePublishTargets(request.getPublishTargets()));

        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    @Override
    @Transactional(readOnly = true)
    public WorkflowResponse getWorkflow(String tenantId, UUID workflowId) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        return toResponse(workflow);
    }

    @Override
    @Transactional(readOnly = true)
    public WorkflowListResponse listWorkflows(
            String tenantId,
            String contentId,
            WorkflowState state,
            String createdBy,
            int page,
            int size) {
        PageRequest pageRequest = PageRequest.of(
                normalizePage(page),
                normalizeSize(size),
                Sort.by(Sort.Direction.DESC, "lastUpdatedAt"));

        Specification<Workflow> spec = tenantSpec(tenantId)
                .and(optionalEquals("contentId", normalizeFilter(contentId)))
                .and(optionalEquals("state", state))
                .and(optionalEquals("createdBy", normalizeFilter(createdBy)));

        Page<Workflow> results = workflowRepository.findAll(spec, pageRequest);
        List<WorkflowResponse> items = results.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        WorkflowListResponse response = new WorkflowListResponse();
        response.setItems(items);
        response.setPage(results.getNumber());
        response.setSize(results.getSize());
        response.setTotal(results.getTotalElements());
        return response;
    }

    @Override
    @Transactional
    public WorkflowResponse submitForReview(
            String tenantId,
            UUID workflowId,
            String userId,
            SubmitForReviewRequest request) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        if (!(workflow.getState() == WorkflowState.DRAFT || workflow.getState() == WorkflowState.REJECTED)) {
            throw new ConflictException("Workflow is not in a submittable state");
        }

        List<String> reviewers = normalizeReviewers(request.getReviewerUserIds());
        if (reviewers.isEmpty()) {
            throw new BadRequestException("At least one reviewer is required");
        }
        int requiredApprovals = request.getRequiredApprovals();
        if (requiredApprovals > reviewers.size()) {
            throw new BadRequestException("requiredApprovals exceeds reviewer count");
        }

        reviewTaskRepository.deleteByWorkflowId(workflowId);
        Instant now = Instant.now();
        List<ReviewTask> tasks = reviewers.stream()
                .map(reviewerId -> buildReviewTask(workflowId, reviewerId, now))
                .collect(Collectors.toList());
        reviewTaskRepository.saveAll(tasks);

        workflow.setState(WorkflowState.IN_REVIEW);
        workflow.setRequiredApprovals(requiredApprovals);
        workflow.setCurrentStep("REVIEW");
        workflow.setLastUpdatedBy(resolveActor(userId));
        workflow.setLastUpdatedAt(now);
        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    @Override
    @Transactional
    public WorkflowResponse approveReview(
            String tenantId,
            UUID workflowId,
            UUID taskId,
            String userId,
            ReviewActionRequest request) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        ensureInReview(workflow);

        ReviewTask task = loadReviewTask(workflowId, taskId);
        if (task.getStatus() != ReviewTaskStatus.PENDING) {
            throw new ConflictException("Review task is not pending");
        }

        task.setStatus(ReviewTaskStatus.APPROVED);
        task.setComment(trimToNull(request.getComment()));
        task.setUpdatedAt(Instant.now());
        reviewTaskRepository.save(task);

        long approvedCount = reviewTaskRepository.countByWorkflowIdAndStatus(
                workflowId, ReviewTaskStatus.APPROVED);
        if (approvedCount >= resolveRequiredApprovals(workflow)) {
            workflow.setState(WorkflowState.APPROVED);
            workflow.setCurrentStep(null);
        }

        workflow.setLastUpdatedBy(resolveActor(userId));
        workflow.setLastUpdatedAt(Instant.now());
        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    @Override
    @Transactional
    public WorkflowResponse rejectReview(
            String tenantId,
            UUID workflowId,
            UUID taskId,
            String userId,
            ReviewActionRequest request) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        ensureInReview(workflow);

        ReviewTask task = loadReviewTask(workflowId, taskId);
        if (task.getStatus() != ReviewTaskStatus.PENDING) {
            throw new ConflictException("Review task is not pending");
        }

        task.setStatus(ReviewTaskStatus.REJECTED);
        task.setComment(trimToNull(request.getComment()));
        task.setUpdatedAt(Instant.now());
        reviewTaskRepository.save(task);

        workflow.setState(WorkflowState.REJECTED);
        workflow.setCurrentStep(null);
        workflow.setLastUpdatedBy(resolveActor(userId));
        workflow.setLastUpdatedAt(Instant.now());
        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    @Override
    @Transactional
    public WorkflowResponse publish(
            String tenantId,
            UUID workflowId,
            String userId,
            PublishWorkflowRequest request) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        if (workflow.getState() != WorkflowState.APPROVED) {
            throw new ConflictException("Workflow is not approved for publish");
        }
        if (request != null && request.getPublishTargets() != null) {
            workflow.setPublishTargetsJson(serializePublishTargets(request.getPublishTargets()));
        }

        workflow.setState(WorkflowState.PUBLISHED);
        workflow.setCurrentStep(null);
        workflow.setLastUpdatedBy(resolveActor(userId));
        workflow.setLastUpdatedAt(Instant.now());
        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    @Override
    @Transactional
    public WorkflowResponse archive(String tenantId, UUID workflowId, String userId) {
        Workflow workflow = loadWorkflow(tenantId, workflowId);
        if (workflow.getState() != WorkflowState.PUBLISHED) {
            throw new ConflictException("Workflow is not published");
        }

        workflow.setState(WorkflowState.ARCHIVED);
        workflow.setCurrentStep(null);
        workflow.setLastUpdatedBy(resolveActor(userId));
        workflow.setLastUpdatedAt(Instant.now());
        workflowRepository.save(workflow);
        return toResponse(workflow);
    }

    private Workflow loadWorkflow(String tenantId, UUID workflowId) {
        return workflowRepository.findByIdAndTenantId(workflowId, tenantId)
                .orElseThrow(() -> new NotFoundException("Workflow not found"));
    }

    private ReviewTask loadReviewTask(UUID workflowId, UUID taskId) {
        return reviewTaskRepository.findByIdAndWorkflowId(taskId, workflowId)
                .orElseThrow(() -> new NotFoundException("Review task not found"));
    }

    private void ensureInReview(Workflow workflow) {
        if (workflow.getState() != WorkflowState.IN_REVIEW) {
            throw new ConflictException("Workflow is not in review");
        }
    }

    private ReviewTask buildReviewTask(UUID workflowId, String reviewerId, Instant now) {
        ReviewTask task = new ReviewTask();
        task.setId(UUID.randomUUID());
        task.setWorkflowId(workflowId);
        task.setAssigneeUserId(reviewerId);
        task.setStatus(ReviewTaskStatus.PENDING);
        task.setCreatedAt(now);
        task.setUpdatedAt(now);
        return task;
    }

    private List<String> normalizeReviewers(List<String> reviewers) {
        if (reviewers == null) {
            return List.of();
        }
        Set<String> unique = new LinkedHashSet<>();
        for (String reviewer : reviewers) {
            if (reviewer == null) {
                continue;
            }
            String trimmed = reviewer.trim();
            if (!trimmed.isEmpty()) {
                unique.add(trimmed);
            }
        }
        return List.copyOf(unique);
    }

    private int resolveRequiredApprovals(Workflow workflow) {
        Integer required = workflow.getRequiredApprovals();
        if (required == null || required <= 0) {
            long totalTasks = reviewTaskRepository.findByWorkflowId(workflow.getId()).size();
            return totalTasks == 0 ? 1 : (int) totalTasks;
        }
        return required;
    }

    private WorkflowResponse toResponse(Workflow workflow) {
        WorkflowResponse response = new WorkflowResponse();
        response.setWorkflowId(workflow.getId());
        response.setTenantId(workflow.getTenantId());
        response.setContentId(workflow.getContentId());
        response.setContentVersionId(workflow.getContentVersionId());
        response.setTitleSnapshot(workflow.getTitleSnapshot());
        response.setState(workflow.getState());
        response.setRequiredApprovals(workflow.getRequiredApprovals());
        response.setCreatedBy(workflow.getCreatedBy());
        response.setCreatedAt(workflow.getCreatedAt());
        response.setLastUpdatedBy(workflow.getLastUpdatedBy());
        response.setLastUpdatedAt(workflow.getLastUpdatedAt());
        response.setCurrentStep(workflow.getCurrentStep());
        response.setPublishTargets(deserializePublishTargets(workflow.getPublishTargetsJson()));
        response.setVersion(workflow.getVersion());

        // Fetch and include review tasks
        List<ReviewTask> reviewTasks = reviewTaskRepository.findByWorkflowId(workflow.getId());
        List<ReviewTaskDto> reviewTaskDtos = reviewTasks.stream()
                .map(this::toReviewTaskDto)
                .collect(Collectors.toList());
        response.setReviewTasks(reviewTaskDtos);

        return response;
    }

    private ReviewTaskDto toReviewTaskDto(ReviewTask task) {
        ReviewTaskDto dto = new ReviewTaskDto();
        dto.setId(task.getId());
        dto.setWorkflowId(task.getWorkflowId());
        dto.setAssigneeUserId(task.getAssigneeUserId());
        dto.setStatus(task.getStatus());
        dto.setComment(task.getComment());
        dto.setCreatedAt(task.getCreatedAt());
        dto.setUpdatedAt(task.getUpdatedAt());
        return dto;
    }

    private String serializePublishTargets(PublishTargets targets) {
        if (targets == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(targets);
        } catch (JacksonException ex) {
            throw new BadRequestException("Invalid publishTargets payload");
        }
    }

    private PublishTargets deserializePublishTargets(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, PublishTargets.class);
        } catch (JacksonException ex) {
            return null;
        }
    }

    private String resolveActor(String userId) {
        if (userId == null || userId.isBlank()) {
            return "system";
        }
        return userId.trim();
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
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

    private String normalizeFilter(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private Specification<Workflow> tenantSpec(String tenantId) {
        return (root, query, cb) -> cb.equal(root.get("tenantId"), tenantId);
    }

    private <T> Specification<Workflow> optionalEquals(String field, T value) {
        if (value == null) {
            return (root, query, cb) -> cb.conjunction();
        }
        return (root, query, cb) -> cb.equal(root.get(field), value);
    }

    @Override
    @Transactional
    public void releaseContent(String tenantId, String userId, ReleaseContentRequest request) {
        Instant now = Instant.now();
        UUID releasedBy = null;
        if (userId != null && !userId.isBlank()) {
            try {
                releasedBy = UUID.fromString(userId.trim());
            } catch (IllegalArgumentException e) {
                // Keep as null if not a valid UUID
            }
        }

        for (String contentIdStr : request.getContentIds()) {
            UUID contentId;
            try {
                contentId = UUID.fromString(contentIdStr.trim());
            } catch (IllegalArgumentException e) {
                continue; // Skip invalid content IDs
            }

            for (String classIdStr : request.getClassIds()) {
                UUID classId;
                try {
                    classId = UUID.fromString(classIdStr.trim());
                } catch (IllegalArgumentException e) {
                    continue; // Skip invalid class IDs
                }

                // Check if already released to this class
                if (releasedContentRepository.existsByTenantIdAndContentIdAndClassId(tenantId, contentId, classId)) {
                    continue; // Already released, skip
                }

                ReleasedContent released = new ReleasedContent();
                released.setId(UUID.randomUUID());
                released.setTenantId(tenantId);
                released.setContentId(contentId);
                released.setContentType(request.getContentType());
                released.setClassId(classId);
                released.setReleasedBy(releasedBy);
                released.setReleasedAt(now);

                releasedContentRepository.save(released);
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReleasedContentResponse> getReleasedContent(String tenantId, UUID classId, String contentType) {
        List<ReleasedContent> items;
        if (contentType != null && !contentType.isBlank()) {
            items = releasedContentRepository.findByTenantIdAndClassIdAndContentType(tenantId, classId, contentType.trim());
        } else {
            items = releasedContentRepository.findByTenantIdAndClassId(tenantId, classId);
        }

        return items.stream()
                .map(this::toReleasedContentResponse)
                .collect(Collectors.toList());
    }

    private ReleasedContentResponse toReleasedContentResponse(ReleasedContent entity) {
        ReleasedContentResponse response = new ReleasedContentResponse();
        response.setId(entity.getId());
        response.setContentId(entity.getContentId());
        response.setContentType(entity.getContentType());
        response.setClassId(entity.getClassId());
        response.setReleasedBy(entity.getReleasedBy());
        response.setReleasedAt(entity.getReleasedAt());
        return response;
    }
}
