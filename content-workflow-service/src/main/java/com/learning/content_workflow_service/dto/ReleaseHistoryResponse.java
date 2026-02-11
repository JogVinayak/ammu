package com.learning.content_workflow_service.dto;

import java.util.List;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class ReleaseHistoryResponse {
    private List<ReleaseHistoryItem> items;
    private int page;
    private int size;
    private long total;

    @Data
    @NoArgsConstructor
    public static class ReleaseHistoryItem {
        private String id;
        private String contentId;
        private String contentType;
        private String classId;
        private String className;
        private String releasedBy;
        private String releasedAt;
    }
}
