package com.learning.graph_relations_service.service;

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
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface GraphRelationsService {
    GraphResponse createGraph(UUID tenantId, GraphCreateRequest request);

    GraphResponse getGraph(UUID tenantId, UUID graphId);

    List<GraphResponse> listGraphs(UUID tenantId, GraphScopeType scopeType, UUID scopeId, GraphStatus status);

    GraphResponse updateGraph(UUID tenantId, UUID graphId, GraphUpdateRequest request);

    void deleteGraph(UUID tenantId, UUID graphId);

    NodeResponse createNode(UUID tenantId, UUID graphId, NodeCreateRequest request);

    NodeResponse getNode(UUID tenantId, UUID graphId, UUID nodeId);

    List<NodeResponse> listNodes(UUID tenantId, UUID graphId, NodeType nodeType, UUID refId);

    NodeResponse updateNode(UUID tenantId, UUID graphId, UUID nodeId, NodeUpdateRequest request);

    void deleteNode(UUID tenantId, UUID graphId, UUID nodeId);

    EdgeResponse createEdge(UUID tenantId, UUID graphId, EdgeCreateRequest request);

    List<EdgeResponse> listEdges(UUID tenantId, UUID graphId, UUID fromNodeId, UUID toNodeId, RelationType relationType);

    EdgeResponse updateEdge(UUID tenantId, UUID graphId, UUID edgeId, EdgeUpdateRequest request);

    void deleteEdge(UUID tenantId, UUID graphId, UUID edgeId);

    GraphSubgraphResponse getSubgraph(UUID tenantId, UUID graphId, UUID nodeId, int depth, int limit);

    GraphSubgraphResponse getNeighbors(UUID tenantId, UUID graphId, UUID nodeId, int depth);

    GraphPathsResponse getPaths(UUID tenantId, UUID graphId, UUID fromNodeId, UUID toNodeId, int maxDepth);

    List<EdgeResponse> getDueEdges(UUID tenantId, UUID graphId, UUID userId, Instant asOf, int limit);

    List<EdgeResponse> getWeakEdges(UUID tenantId, UUID graphId, double threshold, int limit);

    EdgeResponse reinforceEdge(UUID tenantId, EdgeReinforcementRequest request);
}
