package com.learning.mindmap_service.service;

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
import java.util.List;
import java.util.UUID;

public interface MindMapService {
    MindMapCreateResponse create(String tenantId, CreateMindMapRequest request);

    MindMapResponse getById(String tenantId, UUID mindMapId);

    MindMapGraphResponse getGraph(String tenantId, UUID mindMapId, String version);

    NodeResponse upsertNode(String tenantId, UUID mindMapId, UUID nodeId, UpsertNodeRequest request);

    void deleteNode(String tenantId, UUID mindMapId, UUID nodeId);

    EdgeResponse upsertEdge(String tenantId, UUID mindMapId, UUID edgeId, UpsertEdgeRequest request);

    void deleteEdge(String tenantId, UUID mindMapId, UUID edgeId);

    MindMapPublishResponse publish(String tenantId, UUID mindMapId, PublishMindMapRequest request);

    List<NodeResponse> searchNodes(String tenantId, UUID mindMapId, String query, int limit);

    ReviewEdgeResponse reviewEdge(String tenantId, UUID mindMapId, UUID edgeId, ReviewEdgeRequest request);

    List<EdgeResponse> getWeakEdges(String tenantId, String userId, int limit, Double strengthThreshold);
}
