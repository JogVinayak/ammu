package com.learning.graph_relations_service.controller;

import com.learning.graph_relations_service.model.dto.EdgeCreateRequest;
import com.learning.graph_relations_service.model.dto.EdgeReinforcementRequest;
import com.learning.graph_relations_service.model.dto.EdgeResponse;
import com.learning.graph_relations_service.model.dto.EdgeUpdateRequest;
import com.learning.graph_relations_service.model.dto.GraphCreateRequest;
import com.learning.graph_relations_service.model.dto.GraphPathsResponse;
import com.learning.graph_relations_service.model.dto.GraphResponse;
import com.learning.graph_relations_service.model.dto.GraphSubgraphResponse;
import com.learning.graph_relations_service.model.dto.GraphUpdateRequest;
import com.learning.graph_relations_service.model.dto.NodeCreateRequest;
import com.learning.graph_relations_service.model.dto.NodeResponse;
import com.learning.graph_relations_service.model.dto.NodeUpdateRequest;
import com.learning.graph_relations_service.model.enums.GraphScopeType;
import com.learning.graph_relations_service.model.enums.GraphStatus;
import com.learning.graph_relations_service.model.enums.NodeType;
import com.learning.graph_relations_service.model.enums.RelationType;
import com.learning.graph_relations_service.service.GraphRelationsService;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/graph-relations")
public class GraphRelationsController {
    private final GraphRelationsService graphRelationsService;

    @PostMapping("/graphs")
    public GraphResponse createGraph(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestBody GraphCreateRequest request) {
        return graphRelationsService.createGraph(tenantId, request);
    }

    @GetMapping("/graphs/{graphId}")
    public GraphResponse getGraph(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId) {
        return graphRelationsService.getGraph(tenantId, graphId);
    }

    @GetMapping("/graphs")
    public List<GraphResponse> listGraphs(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestParam(required = false) GraphScopeType scopeType,
            @RequestParam(required = false) UUID scopeId,
            @RequestParam(required = false) GraphStatus status) {
        return graphRelationsService.listGraphs(tenantId, scopeType, scopeId, status);
    }

    @PatchMapping("/graphs/{graphId}")
    public GraphResponse updateGraph(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestBody GraphUpdateRequest request) {
        return graphRelationsService.updateGraph(tenantId, graphId, request);
    }

    @DeleteMapping("/graphs/{graphId}")
    public ResponseEntity<Void> deleteGraph(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID graphId) {
        graphRelationsService.deleteGraph(tenantId, graphId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/graphs/{graphId}/nodes")
    public NodeResponse createNode(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestBody NodeCreateRequest request) {
        return graphRelationsService.createNode(tenantId, graphId, request);
    }

    @GetMapping("/graphs/{graphId}/nodes")
    public List<NodeResponse> listNodes(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestParam(name = "type", required = false) NodeType nodeType,
            @RequestParam(required = false) UUID refId) {
        return graphRelationsService.listNodes(tenantId, graphId, nodeType, refId);
    }

    @GetMapping("/graphs/{graphId}/nodes/{nodeId}")
    public NodeResponse getNode(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @PathVariable UUID nodeId) {
        return graphRelationsService.getNode(tenantId, graphId, nodeId);
    }

    @PatchMapping("/graphs/{graphId}/nodes/{nodeId}")
    public NodeResponse updateNode(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @PathVariable UUID nodeId, @RequestBody NodeUpdateRequest request) {
        return graphRelationsService.updateNode(tenantId, graphId, nodeId, request);
    }

    @DeleteMapping("/graphs/{graphId}/nodes/{nodeId}")
    public ResponseEntity<Void> deleteNode(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @PathVariable UUID nodeId) {
        graphRelationsService.deleteNode(tenantId, graphId, nodeId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/graphs/{graphId}/edges")
    public EdgeResponse createEdge(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestBody EdgeCreateRequest request) {
        return graphRelationsService.createEdge(tenantId, graphId, request);
    }

    @GetMapping("/graphs/{graphId}/edges")
    public List<EdgeResponse> listEdges(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestParam(name = "from", required = false) UUID fromNodeId,
            @RequestParam(name = "to", required = false) UUID toNodeId,
            @RequestParam(name = "type", required = false) RelationType relationType) {
        return graphRelationsService.listEdges(tenantId, graphId, fromNodeId, toNodeId, relationType);
    }

    @PatchMapping("/graphs/{graphId}/edges/{edgeId}")
    public EdgeResponse updateEdge(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @PathVariable UUID edgeId, @RequestBody EdgeUpdateRequest request) {
        return graphRelationsService.updateEdge(tenantId, graphId, edgeId, request);
    }

    @DeleteMapping("/graphs/{graphId}/edges/{edgeId}")
    public ResponseEntity<Void> deleteEdge(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @PathVariable UUID edgeId) {
        graphRelationsService.deleteEdge(tenantId, graphId, edgeId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/graphs/{graphId}/subgraph")
    public GraphSubgraphResponse getSubgraph(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID graphId, @RequestParam UUID nodeId,
            @RequestParam(defaultValue = "2") int depth, @RequestParam(defaultValue = "500") int limit) {
        return graphRelationsService.getSubgraph(tenantId, graphId, nodeId, depth, limit);
    }

    @GetMapping("/graphs/{graphId}/neighbors")
    public GraphSubgraphResponse getNeighbors(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID graphId, @RequestParam UUID nodeId,
            @RequestParam(defaultValue = "1") int depth) {
        return graphRelationsService.getNeighbors(tenantId, graphId, nodeId, depth);
    }

    @GetMapping("/graphs/{graphId}/paths")
    public GraphPathsResponse getPaths(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestParam UUID fromNodeId, @RequestParam UUID toNodeId,
            @RequestParam(defaultValue = "6") int maxDepth) {
        return graphRelationsService.getPaths(tenantId, graphId, fromNodeId, toNodeId, maxDepth);
    }

    @GetMapping("/graphs/{graphId}/due-edges")
    public List<EdgeResponse> getDueEdges(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestParam UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant asOf,
            @RequestParam(defaultValue = "200") int limit) {
        return graphRelationsService.getDueEdges(tenantId, graphId, userId, asOf, limit);
    }

    @GetMapping("/graphs/{graphId}/weak-edges")
    public List<EdgeResponse> getWeakEdges(@RequestHeader("X-Tenant-Id") UUID tenantId, @PathVariable UUID graphId,
            @RequestParam(defaultValue = "0.35") double threshold,
            @RequestParam(defaultValue = "200") int limit) {
        return graphRelationsService.getWeakEdges(tenantId, graphId, threshold, limit);
    }

    @PostMapping("/signals/edge-reinforcement")
    public EdgeResponse reinforceEdge(@RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestBody EdgeReinforcementRequest request) {
        return graphRelationsService.reinforceEdge(tenantId, request);
    }
}
