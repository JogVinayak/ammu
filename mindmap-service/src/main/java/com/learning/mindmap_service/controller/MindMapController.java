package com.learning.mindmap_service.controller;

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
import com.learning.mindmap_service.service.MindMapService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/mindmaps")
public class MindMapController {
    private final MindMapService mindMapService;

    @PostMapping
    public ResponseEntity<MindMapCreateResponse> create(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @Valid @RequestBody CreateMindMapRequest request) {
        MindMapCreateResponse response = mindMapService.create(tenantId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{mindMapId}")
    public MindMapResponse getById(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId) {
        return mindMapService.getById(tenantId, mindMapId);
    }

    @GetMapping("/{mindMapId}/graph")
    public MindMapGraphResponse getGraph(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @RequestParam(required = false) String version) {
        return mindMapService.getGraph(tenantId, mindMapId, version);
    }

    @PutMapping("/{mindMapId}/nodes/{nodeId}")
    public NodeResponse upsertNode(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @PathVariable UUID nodeId,
            @Valid @RequestBody UpsertNodeRequest request) {
        return mindMapService.upsertNode(tenantId, mindMapId, nodeId, request);
    }

    @DeleteMapping("/{mindMapId}/nodes/{nodeId}")
    public ResponseEntity<Void> deleteNode(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @PathVariable UUID nodeId) {
        mindMapService.deleteNode(tenantId, mindMapId, nodeId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{mindMapId}/edges/{edgeId}")
    public EdgeResponse upsertEdge(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @PathVariable UUID edgeId,
            @Valid @RequestBody UpsertEdgeRequest request) {
        return mindMapService.upsertEdge(tenantId, mindMapId, edgeId, request);
    }

    @DeleteMapping("/{mindMapId}/edges/{edgeId}")
    public ResponseEntity<Void> deleteEdge(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @PathVariable UUID edgeId) {
        mindMapService.deleteEdge(tenantId, mindMapId, edgeId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{mindMapId}/publish")
    public MindMapPublishResponse publish(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @Valid @RequestBody PublishMindMapRequest request) {
        return mindMapService.publish(tenantId, mindMapId, request);
    }

    @GetMapping("/{mindMapId}/nodes/search")
    public List<NodeResponse> searchNodes(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @RequestParam("q") String query,
            @RequestParam(defaultValue = "20") int limit) {
        return mindMapService.searchNodes(tenantId, mindMapId, query, limit);
    }

    @PostMapping("/{mindMapId}/edges/{edgeId}/review")
    public ReviewEdgeResponse reviewEdge(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID mindMapId,
            @PathVariable UUID edgeId,
            @Valid @RequestBody ReviewEdgeRequest request) {
        return mindMapService.reviewEdge(tenantId, mindMapId, edgeId, request);
    }

    @GetMapping("/revision/weak")
    public List<EdgeResponse> getWeakEdges(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestParam(required = false) String userId,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(required = false) Double strengthThreshold) {
        return mindMapService.getWeakEdges(tenantId, userId, limit, strengthThreshold);
    }
}
