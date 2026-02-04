package com.learning.mindmap_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.learning.mindmap_service.model.dto.CreateMindMapRequest;
import com.learning.mindmap_service.model.dto.EdgeResponse;
import com.learning.mindmap_service.model.dto.MindMapCreateResponse;
import com.learning.mindmap_service.model.dto.MindMapGraphResponse;
import com.learning.mindmap_service.model.dto.MindMapPublishResponse;
import com.learning.mindmap_service.model.dto.MindMapResponse;
import com.learning.mindmap_service.model.dto.NodeResponse;
import com.learning.mindmap_service.model.dto.PublishMindMapRequest;
import com.learning.mindmap_service.model.dto.ReviewEdgeRequest;
import com.learning.mindmap_service.model.dto.ReviewEdgeResponse;
import com.learning.mindmap_service.model.dto.UpsertEdgeRequest;
import com.learning.mindmap_service.model.dto.UpsertNodeRequest;
import com.learning.mindmap_service.model.entity.Edge;
import com.learning.mindmap_service.model.entity.MindMap;
import com.learning.mindmap_service.model.entity.MindMapVersion;
import com.learning.mindmap_service.model.entity.Node;
import com.learning.mindmap_service.model.enums.EdgeReviewResult;
import com.learning.mindmap_service.model.enums.MindMapStatus;
import com.learning.mindmap_service.model.enums.MindMapVersionStatus;
import com.learning.mindmap_service.model.enums.MindMapVisibility;
import com.learning.mindmap_service.repository.EdgeRepository;
import com.learning.mindmap_service.repository.MindMapRepository;
import com.learning.mindmap_service.repository.MindMapVersionRepository;
import com.learning.mindmap_service.repository.NodeRepository;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
@Transactional
public class DefaultMindMapService implements MindMapService {
    private static final double DEFAULT_STRENGTH = 0.5;
    private static final long DEFAULT_TTL_SECONDS = 86_400;
    private static final double DEFAULT_WEAK_THRESHOLD = 0.4;
    private static final int DEFAULT_SEARCH_LIMIT = 20;
    private static final int MAX_LIMIT = 200;

    private final MindMapRepository mindMapRepository;
    private final MindMapVersionRepository mindMapVersionRepository;
    private final NodeRepository nodeRepository;
    private final EdgeRepository edgeRepository;
    private final ObjectMapper objectMapper;

    @Override
    public MindMapCreateResponse create(String tenantId, CreateMindMapRequest request) {
        Instant now = Instant.now();

        MindMap mindMap = new MindMap();
        mindMap.setMindMapId(UUID.randomUUID());
        mindMap.setTenantId(tenantId);
        mindMap.setTitle(request.getTitle());
        mindMap.setDescription(request.getDescription());
        mindMap.setSubject(request.getSubject());
        mindMap.setGrade(request.getGrade());
        mindMap.setTagsJson(writeTagsJson(request.getTags()));
        mindMap.setStatus(MindMapStatus.DRAFT);
        mindMap.setVisibility(defaultVisibility(request.getVisibility()));
        mindMap.setCreatedBy(request.getCreatedBy());
        mindMap.setCreatedAt(now);
        mindMap.setUpdatedAt(now);

        mindMapRepository.save(mindMap);

        MindMapCreateResponse response = new MindMapCreateResponse();
        response.setMindMapId(mindMap.getMindMapId());
        response.setStatus(mindMap.getStatus());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MindMapResponse> list(String tenantId, int limit, int offset) {
        int safeLimit = clampLimit(limit, 20);
        int page = offset / Math.max(safeLimit, 1);
        return mindMapRepository.findByTenantIdOrderByUpdatedAtDesc(tenantId, PageRequest.of(page, safeLimit))
                .stream()
                .map(this::toMindMapResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public MindMapResponse getById(String tenantId, UUID mindMapId) {
        MindMap mindMap = requireMindMap(tenantId, mindMapId);
        return toMindMapResponse(mindMap);
    }

    @Override
    @Transactional(readOnly = true)
    public MindMapGraphResponse getGraph(String tenantId, UUID mindMapId, String version) {
        MindMap mindMap = requireMindMap(tenantId, mindMapId);
        List<NodeResponse> nodes = nodeRepository.findByTenantIdAndMindMapId(tenantId, mindMapId)
                .stream()
                .map(this::toNodeResponse)
                .collect(Collectors.toList());
        List<EdgeResponse> edges = edgeRepository.findByTenantIdAndMindMapId(tenantId, mindMapId)
                .stream()
                .map(this::toEdgeResponse)
                .collect(Collectors.toList());

        MindMapGraphResponse response = new MindMapGraphResponse();
        response.setMindMapId(mindMap.getMindMapId());
        response.setVersion(version == null || version.isBlank() ? mindMap.getStatus().name().toLowerCase() : version);
        response.setNodes(nodes);
        response.setEdges(edges);
        return response;
    }

    @Override
    public NodeResponse upsertNode(String tenantId, UUID mindMapId, UUID nodeId, UpsertNodeRequest request) {
        requireMindMap(tenantId, mindMapId);
        Instant now = Instant.now();

        Node node = nodeRepository
                .findByNodeIdAndTenantIdAndMindMapId(nodeId, tenantId, mindMapId)
                .orElseGet(() -> createNodeShell(tenantId, mindMapId, nodeId, now));

        node.setType(request.getType());
        node.setTitle(request.getTitle());
        node.setBodyMarkdown(request.getBodyMarkdown());
        node.setContentId(request.getContentId());
        node.setContentVersionId(request.getContentVersionId());
        node.setPosX(request.getPosX());
        node.setPosY(request.getPosY());
        node.setMetaJson(request.getMetaJson());
        node.setUpdatedAt(now);

        nodeRepository.save(node);
        return toNodeResponse(node);
    }

    @Override
    public void deleteNode(String tenantId, UUID mindMapId, UUID nodeId) {
        requireMindMap(tenantId, mindMapId);
        edgeRepository.deleteByTenantIdAndMindMapIdAndFromNodeId(tenantId, mindMapId, nodeId);
        edgeRepository.deleteByTenantIdAndMindMapIdAndToNodeId(tenantId, mindMapId, nodeId);
        nodeRepository.deleteByNodeIdAndTenantIdAndMindMapId(nodeId, tenantId, mindMapId);
    }

    @Override
    public EdgeResponse upsertEdge(String tenantId, UUID mindMapId, UUID edgeId, UpsertEdgeRequest request) {
        requireMindMap(tenantId, mindMapId);
        requireNode(tenantId, mindMapId, request.getFromNodeId());
        requireNode(tenantId, mindMapId, request.getToNodeId());

        Instant now = Instant.now();

        Edge edge = edgeRepository
                .findByEdgeIdAndTenantIdAndMindMapId(edgeId, tenantId, mindMapId)
                .orElseGet(() -> createEdgeShell(tenantId, mindMapId, edgeId, now));

        edge.setFromNodeId(request.getFromNodeId());
        edge.setToNodeId(request.getToNodeId());
        edge.setRelation(request.getRelation());
        edge.setWeight(request.getWeight());
        edge.setStrength(request.getStrength());
        edge.setTtlSeconds(request.getTtlSeconds());
        edge.setUpdatedAt(now);

        edgeRepository.save(edge);
        return toEdgeResponse(edge);
    }

    @Override
    public void deleteEdge(String tenantId, UUID mindMapId, UUID edgeId) {
        requireMindMap(tenantId, mindMapId);
        edgeRepository.deleteByEdgeIdAndTenantIdAndMindMapId(edgeId, tenantId, mindMapId);
    }

    @Override
    public MindMapPublishResponse publish(String tenantId, UUID mindMapId, PublishMindMapRequest request) {
        MindMap mindMap = requireMindMap(tenantId, mindMapId);
        Instant now = Instant.now();

        int nextVersion = mindMapVersionRepository.findTopByMindMapIdOrderByVersionNumberDesc(mindMapId)
                .map(version -> version.getVersionNumber() + 1)
                .orElse(1);

        MindMapVersion version = new MindMapVersion();
        version.setMindMapVersionId(UUID.randomUUID());
        version.setMindMapId(mindMapId);
        version.setVersionNumber(nextVersion);
        version.setStatus(MindMapVersionStatus.PUBLISHED);
        version.setCreatedBy(resolveActor(mindMap));
        version.setCreatedAt(now);
        mindMapVersionRepository.save(version);

        mindMap.setStatus(MindMapStatus.PUBLISHED);
        mindMap.setPublishedVersionId(version.getMindMapVersionId());
        mindMap.setUpdatedAt(now);
        mindMapRepository.save(mindMap);

        MindMapPublishResponse response = new MindMapPublishResponse();
        response.setMindMapId(mindMap.getMindMapId());
        response.setStatus(mindMap.getStatus());
        response.setPublishedVersionId(mindMap.getPublishedVersionId());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<NodeResponse> searchNodes(String tenantId, UUID mindMapId, String query, int limit) {
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }
        int safeLimit = clampLimit(limit, DEFAULT_SEARCH_LIMIT);
        return nodeRepository.findByTenantIdAndMindMapIdAndTitleContainingIgnoreCase(
                        tenantId,
                        mindMapId,
                        query.trim(),
                        PageRequest.of(0, safeLimit))
                .stream()
                .map(this::toNodeResponse)
                .collect(Collectors.toList());
    }

    @Override
    public ReviewEdgeResponse reviewEdge(String tenantId, UUID mindMapId, UUID edgeId, ReviewEdgeRequest request) {
        Edge edge = requireEdge(tenantId, mindMapId, edgeId);
        Instant now = Instant.now();

        double currentStrength = edge.getStrength() == null ? DEFAULT_STRENGTH : edge.getStrength();
        double delta = strengthDelta(request.getResult());
        double newStrength = clampStrength(currentStrength + delta);

        long baseTtl = edge.getTtlSeconds() == null ? DEFAULT_TTL_SECONDS : edge.getTtlSeconds();
        long newTtl = nextTtlSeconds(baseTtl, request.getResult());

        edge.setStrength(newStrength);
        edge.setTtlSeconds(newTtl);
        edge.setLastReviewedAt(now);
        edge.setExpiresAt(now.plusSeconds(newTtl));
        edge.setUpdatedAt(now);
        edgeRepository.save(edge);

        ReviewEdgeResponse response = new ReviewEdgeResponse();
        response.setEdgeId(edge.getEdgeId());
        response.setStrength(edge.getStrength());
        response.setTtlSeconds(edge.getTtlSeconds());
        response.setExpiresAt(edge.getExpiresAt());
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<EdgeResponse> getWeakEdges(String tenantId, String userId, int limit, Double strengthThreshold) {
        int safeLimit = clampLimit(limit, 50);
        double threshold = strengthThreshold == null ? DEFAULT_WEAK_THRESHOLD : strengthThreshold;
        return edgeRepository.findWeakEdges(tenantId, Instant.now(), threshold, PageRequest.of(0, safeLimit))
                .stream()
                .map(this::toEdgeResponse)
                .collect(Collectors.toList());
    }

    private MindMap requireMindMap(String tenantId, UUID mindMapId) {
        return mindMapRepository.findByMindMapIdAndTenantId(mindMapId, tenantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Mind map not found"));
    }

    private Node requireNode(String tenantId, UUID mindMapId, UUID nodeId) {
        return nodeRepository.findByNodeIdAndTenantIdAndMindMapId(nodeId, tenantId, mindMapId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Node not found"));
    }

    private Edge requireEdge(String tenantId, UUID mindMapId, UUID edgeId) {
        return edgeRepository.findByEdgeIdAndTenantIdAndMindMapId(edgeId, tenantId, mindMapId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Edge not found"));
    }

    private MindMapVisibility defaultVisibility(MindMapVisibility visibility) {
        return visibility == null ? MindMapVisibility.TENANT : visibility;
    }

    private String writeTagsJson(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(tags);
        } catch (JsonProcessingException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid tags payload");
        }
    }

    private List<String> readTags(String tagsJson) {
        if (tagsJson == null || tagsJson.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(tagsJson, new TypeReference<List<String>>() {});
        } catch (JsonProcessingException ex) {
            return Collections.emptyList();
        }
    }

    private MindMapResponse toMindMapResponse(MindMap mindMap) {
        MindMapResponse response = new MindMapResponse();
        response.setMindMapId(mindMap.getMindMapId());
        response.setTenantId(mindMap.getTenantId());
        response.setTitle(mindMap.getTitle());
        response.setDescription(mindMap.getDescription());
        response.setSubject(mindMap.getSubject());
        response.setGrade(mindMap.getGrade());
        response.setTags(readTags(mindMap.getTagsJson()));
        response.setStatus(mindMap.getStatus());
        response.setVisibility(mindMap.getVisibility());
        response.setCreatedBy(mindMap.getCreatedBy());
        response.setUpdatedBy(mindMap.getUpdatedBy());
        response.setCreatedAt(mindMap.getCreatedAt());
        response.setUpdatedAt(mindMap.getUpdatedAt());
        response.setPublishedVersionId(mindMap.getPublishedVersionId());
        return response;
    }

    private NodeResponse toNodeResponse(Node node) {
        NodeResponse response = new NodeResponse();
        response.setNodeId(node.getNodeId());
        response.setMindMapId(node.getMindMapId());
        response.setType(node.getType());
        response.setTitle(node.getTitle());
        response.setBodyMarkdown(node.getBodyMarkdown());
        response.setContentId(node.getContentId());
        response.setContentVersionId(node.getContentVersionId());
        response.setPosX(node.getPosX());
        response.setPosY(node.getPosY());
        response.setMetaJson(node.getMetaJson());
        response.setCreatedAt(node.getCreatedAt());
        response.setUpdatedAt(node.getUpdatedAt());
        return response;
    }

    private EdgeResponse toEdgeResponse(Edge edge) {
        EdgeResponse response = new EdgeResponse();
        response.setEdgeId(edge.getEdgeId());
        response.setMindMapId(edge.getMindMapId());
        response.setFromNodeId(edge.getFromNodeId());
        response.setToNodeId(edge.getToNodeId());
        response.setRelation(edge.getRelation());
        response.setWeight(edge.getWeight());
        response.setStrength(edge.getStrength());
        response.setTtlSeconds(edge.getTtlSeconds());
        response.setLastReviewedAt(edge.getLastReviewedAt());
        response.setExpiresAt(edge.getExpiresAt());
        response.setCreatedAt(edge.getCreatedAt());
        response.setUpdatedAt(edge.getUpdatedAt());
        return response;
    }

    private Node createNodeShell(String tenantId, UUID mindMapId, UUID nodeId, Instant now) {
        Node node = new Node();
        node.setNodeId(nodeId);
        node.setTenantId(tenantId);
        node.setMindMapId(mindMapId);
        node.setCreatedAt(now);
        node.setUpdatedAt(now);
        return node;
    }

    private Edge createEdgeShell(String tenantId, UUID mindMapId, UUID edgeId, Instant now) {
        Edge edge = new Edge();
        edge.setEdgeId(edgeId);
        edge.setTenantId(tenantId);
        edge.setMindMapId(mindMapId);
        edge.setCreatedAt(now);
        edge.setUpdatedAt(now);
        return edge;
    }

    private UUID resolveActor(MindMap mindMap) {
        if (mindMap.getUpdatedBy() != null) {
            return mindMap.getUpdatedBy();
        }
        return mindMap.getCreatedBy();
    }

    private double strengthDelta(EdgeReviewResult result) {
        if (result == null) {
            return 0.0;
        }
        return switch (result) {
            case CORRECT -> 0.1;
            case PARTIAL -> 0.05;
            case WRONG -> -0.1;
        };
    }

    private double clampStrength(double value) {
        if (value < 0.0) {
            return 0.0;
        }
        if (value > 1.0) {
            return 1.0;
        }
        return value;
    }

    private long nextTtlSeconds(long baseTtl, EdgeReviewResult result) {
        if (result == null) {
            return baseTtl;
        }
        return switch (result) {
            case CORRECT -> Math.max(baseTtl, Math.round(baseTtl * 1.5));
            case PARTIAL -> Math.max(baseTtl, Math.round(baseTtl * 1.1));
            case WRONG -> Math.max(3600L, Math.round(baseTtl * 0.5));
        };
    }

    private int clampLimit(int limit, int defaultLimit) {
        if (limit <= 0) {
            return defaultLimit;
        }
        return Math.min(limit, MAX_LIMIT);
    }
}
