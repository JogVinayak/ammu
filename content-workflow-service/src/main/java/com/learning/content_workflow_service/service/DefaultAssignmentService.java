package com.learning.content_workflow_service.service;

import com.learning.content_workflow_service.client.NotificationClient;
import com.learning.content_workflow_service.client.UserProfileClient;
import com.learning.content_workflow_service.dto.AssignmentListResponse;
import com.learning.content_workflow_service.dto.AssignmentProgressResponse;
import com.learning.content_workflow_service.dto.AssignmentResponse;
import com.learning.content_workflow_service.dto.CreateAssignmentRequest;
import com.learning.content_workflow_service.dto.CycleConfig;
import com.learning.content_workflow_service.dto.StudentAssignmentResponse;
import com.learning.content_workflow_service.dto.UpdateAssignmentRequest;
import com.learning.content_workflow_service.entity.Assignment;
import com.learning.content_workflow_service.entity.StudentAssignment;
import com.learning.content_workflow_service.enums.AssignmentStatus;
import com.learning.content_workflow_service.enums.StudentAssignmentStatus;
import com.learning.content_workflow_service.exception.BadRequestException;
import com.learning.content_workflow_service.exception.ConflictException;
import com.learning.content_workflow_service.exception.NotFoundException;
import com.learning.content_workflow_service.repository.AssignmentRepository;
import com.learning.content_workflow_service.repository.StudentAssignmentRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
public class DefaultAssignmentService implements AssignmentService {
    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 100;

    private final AssignmentRepository assignmentRepository;
    private final StudentAssignmentRepository studentAssignmentRepository;
    private final UserProfileClient userProfileClient;
    private final NotificationClient notificationClient;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public AssignmentResponse createAssignment(String tenantId, String userId, CreateAssignmentRequest request) {
        if (assignmentRepository.existsByTenantIdAndNoteIdAndClassIdAndStatus(
                tenantId, request.getNoteId(), request.getClassId(), AssignmentStatus.ACTIVE)) {
            throw new ConflictException("Active assignment already exists for this note in this class");
        }

        Instant now = Instant.now();
        String actor = resolveActor(userId);

        Assignment assignment = new Assignment();
        assignment.setId(UUID.randomUUID());
        assignment.setTenantId(tenantId);
        assignment.setNoteId(request.getNoteId());
        assignment.setClassId(request.getClassId());
        assignment.setTeacherId(actor);
        assignment.setTitle(request.getTitle());
        assignment.setDescription(request.getDescription());
        assignment.setStatus(AssignmentStatus.ACTIVE);
        assignment.setDueDate(request.getDueDate());
        assignment.setCycleConfigJson(serializeCycleConfig(request.getCycleConfig()));
        assignment.setStudentCount(0);
        assignment.setCreatedAt(now);
        assignment.setUpdatedAt(now);

        assignmentRepository.save(assignment);

        // Fetch students in the class and create student assignments
        List<UserProfileClient.StudentInfo> students =
                userProfileClient.getStudentsByClassId(tenantId, request.getClassId());

        List<StudentAssignment> studentAssignments = new ArrayList<>();
        for (UserProfileClient.StudentInfo student : students) {
            StudentAssignment sa = new StudentAssignment();
            sa.setId(UUID.randomUUID());
            sa.setTenantId(tenantId);
            sa.setAssignmentId(assignment.getId());
            sa.setStudentId(student.getId());
            sa.setStudentName(student.getName());
            sa.setStatus(StudentAssignmentStatus.PENDING);
            sa.setCreatedAt(now);
            sa.setUpdatedAt(now);
            studentAssignments.add(sa);
        }

        if (!studentAssignments.isEmpty()) {
            studentAssignmentRepository.saveAll(studentAssignments);
        }

        assignment.setStudentCount(students.size());
        assignmentRepository.save(assignment);

        // Send notifications (fire-and-forget)
        sendAssignmentNotifications(tenantId, assignment.getId(), assignment.getTitle(), students);

        return toResponse(assignment);
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentResponse getAssignment(String tenantId, UUID assignmentId) {
        Assignment assignment = loadAssignment(tenantId, assignmentId);
        return toResponse(assignment);
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentListResponse listAssignments(
            String tenantId, UUID classId, String teacherId, AssignmentStatus status, int page, int size) {
        PageRequest pageRequest = PageRequest.of(
                normalizePage(page),
                normalizeSize(size),
                Sort.by(Sort.Direction.DESC, "createdAt"));

        Specification<Assignment> spec = tenantSpec(tenantId)
                .and(optionalEquals("classId", classId))
                .and(optionalEquals("teacherId", normalizeFilter(teacherId)))
                .and(optionalEquals("status", status));

        Page<Assignment> results = assignmentRepository.findAll(spec, pageRequest);
        List<AssignmentResponse> items = results.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return AssignmentListResponse.builder()
                .items(items)
                .page(results.getNumber())
                .size(results.getSize())
                .totalElements(results.getTotalElements())
                .totalPages(results.getTotalPages())
                .build();
    }

    @Override
    @Transactional
    public AssignmentResponse updateAssignment(
            String tenantId, UUID assignmentId, String userId, UpdateAssignmentRequest request) {
        Assignment assignment = loadAssignment(tenantId, assignmentId);

        if (assignment.getStatus() != AssignmentStatus.ACTIVE) {
            throw new ConflictException("Only active assignments can be updated");
        }

        if (request.getTitle() != null) {
            assignment.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            assignment.setDescription(request.getDescription());
        }
        if (request.getDueDate() != null) {
            assignment.setDueDate(request.getDueDate());
        }
        if (request.getCycleConfig() != null) {
            assignment.setCycleConfigJson(serializeCycleConfig(request.getCycleConfig()));
        }

        assignment.setUpdatedAt(Instant.now());
        assignmentRepository.save(assignment);

        return toResponse(assignment);
    }

    @Override
    @Transactional
    public void cancelAssignment(String tenantId, UUID assignmentId) {
        Assignment assignment = loadAssignment(tenantId, assignmentId);

        assignment.setStatus(AssignmentStatus.CANCELLED);
        assignment.setUpdatedAt(Instant.now());
        assignmentRepository.save(assignment);

        studentAssignmentRepository.deleteByAssignmentId(assignmentId);
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentListResponse listStudentAssignments(String tenantId, String studentId, int page, int size) {
        PageRequest pageRequest = PageRequest.of(
                normalizePage(page),
                normalizeSize(size),
                Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<StudentAssignment> studentAssignments =
                studentAssignmentRepository.findByTenantIdAndStudentId(tenantId, studentId, pageRequest);

        // Collect distinct assignment IDs and load the parent assignments
        List<UUID> assignmentIds = studentAssignments.getContent().stream()
                .map(StudentAssignment::getAssignmentId)
                .distinct()
                .collect(Collectors.toList());

        Map<UUID, Assignment> assignmentMap = assignmentRepository.findAllById(assignmentIds).stream()
                .collect(Collectors.toMap(Assignment::getId, Function.identity()));

        List<AssignmentResponse> items = studentAssignments.getContent().stream()
                .map(sa -> assignmentMap.get(sa.getAssignmentId()))
                .filter(a -> a != null)
                .map(this::toResponse)
                .collect(Collectors.toList());

        return AssignmentListResponse.builder()
                .items(items)
                .page(studentAssignments.getNumber())
                .size(studentAssignments.getSize())
                .totalElements(studentAssignments.getTotalElements())
                .totalPages(studentAssignments.getTotalPages())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentProgressResponse getAssignmentProgress(String tenantId, UUID assignmentId) {
        Assignment assignment = loadAssignment(tenantId, assignmentId);

        List<StudentAssignment> studentAssignments = studentAssignmentRepository.findByAssignmentId(assignmentId);

        int pendingCount = 0;
        int inProgressCount = 0;
        int completedCount = 0;
        int overdueCount = 0;

        List<StudentAssignmentResponse> responses = new ArrayList<>();
        for (StudentAssignment sa : studentAssignments) {
            switch (sa.getStatus()) {
                case PENDING -> pendingCount++;
                case IN_PROGRESS -> inProgressCount++;
                case COMPLETED -> completedCount++;
                case OVERDUE -> overdueCount++;
            }
            responses.add(toStudentAssignmentResponse(sa));
        }

        return AssignmentProgressResponse.builder()
                .assignmentId(assignment.getId())
                .totalStudents(studentAssignments.size())
                .pendingCount(pendingCount)
                .inProgressCount(inProgressCount)
                .completedCount(completedCount)
                .overdueCount(overdueCount)
                .studentAssignments(responses)
                .build();
    }

    // --- Private helpers ---

    private Assignment loadAssignment(String tenantId, UUID assignmentId) {
        return assignmentRepository.findByIdAndTenantId(assignmentId, tenantId)
                .orElseThrow(() -> new NotFoundException("Assignment not found: " + assignmentId));
    }

    private AssignmentResponse toResponse(Assignment assignment) {
        return AssignmentResponse.builder()
                .assignmentId(assignment.getId())
                .tenantId(assignment.getTenantId())
                .noteId(assignment.getNoteId())
                .classId(assignment.getClassId())
                .teacherId(assignment.getTeacherId())
                .title(assignment.getTitle())
                .description(assignment.getDescription())
                .status(assignment.getStatus())
                .dueDate(assignment.getDueDate())
                .cycleConfig(deserializeCycleConfig(assignment.getCycleConfigJson()))
                .studentCount(assignment.getStudentCount())
                .createdAt(assignment.getCreatedAt())
                .updatedAt(assignment.getUpdatedAt())
                .version(assignment.getVersion())
                .build();
    }

    private StudentAssignmentResponse toStudentAssignmentResponse(StudentAssignment sa) {
        return StudentAssignmentResponse.builder()
                .studentAssignmentId(sa.getId())
                .assignmentId(sa.getAssignmentId())
                .studentId(sa.getStudentId())
                .studentName(sa.getStudentName())
                .status(sa.getStatus())
                .startedAt(sa.getStartedAt())
                .completedAt(sa.getCompletedAt())
                .recallScheduleId(sa.getRecallScheduleId())
                .createdAt(sa.getCreatedAt())
                .updatedAt(sa.getUpdatedAt())
                .build();
    }

    private String serializeCycleConfig(CycleConfig config) {
        if (config == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(config);
        } catch (JacksonException ex) {
            throw new BadRequestException("Invalid cycleConfig payload");
        }
    }

    private CycleConfig deserializeCycleConfig(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, CycleConfig.class);
        } catch (JacksonException ex) {
            return null;
        }
    }

    private void sendAssignmentNotifications(
            String tenantId, UUID assignmentId, String title, List<UserProfileClient.StudentInfo> students) {
        try {
            List<UUID> studentUuids = new ArrayList<>();
            for (UserProfileClient.StudentInfo student : students) {
                if (student.getId() != null) {
                    try {
                        studentUuids.add(UUID.fromString(student.getId()));
                    } catch (IllegalArgumentException e) {
                        // Skip invalid student IDs
                    }
                }
            }

            if (studentUuids.isEmpty()) {
                return;
            }

            String notifTitle = "New Assignment";
            String message = title != null
                    ? "You have been assigned \"" + title + "\"."
                    : "You have a new assignment.";

            int sent = notificationClient.sendNotifications(
                    tenantId, studentUuids, "ASSIGNMENT_CREATED", notifTitle, message, assignmentId, "ASSIGNMENT");

            log.info("Sent {} assignment notifications for assignment {} in tenant {}", sent, assignmentId, tenantId);
        } catch (Exception e) {
            log.warn("Failed to send assignment notifications: {}", e.getMessage());
        }
    }

    private String resolveActor(String userId) {
        if (userId == null || userId.isBlank()) {
            return "system";
        }
        return userId.trim();
    }

    private String normalizeFilter(String value) {
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

    private Specification<Assignment> tenantSpec(String tenantId) {
        return (root, query, cb) -> cb.equal(root.get("tenantId"), tenantId);
    }

    private <T> Specification<Assignment> optionalEquals(String field, T value) {
        if (value == null) {
            return (root, query, cb) -> cb.conjunction();
        }
        return (root, query, cb) -> cb.equal(root.get(field), value);
    }
}
