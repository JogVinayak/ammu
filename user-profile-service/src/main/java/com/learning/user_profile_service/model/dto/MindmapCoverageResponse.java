package com.learning.user_profile_service.model.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class MindmapCoverageResponse {
    UUID mindmapId;
    Integer totalNodes;
    Integer nodesStarted;
    Integer nodesMastered;
    BigDecimal coveragePercent;
    BigDecimal averageConfidence;
    List<KnowledgeCoverageResponse> nodeCoverage;
}
