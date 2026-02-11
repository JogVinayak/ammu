package com.learning.content_workflow_service.repository;

import com.learning.content_workflow_service.entity.ReleasedContent;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReleasedContentRepository extends JpaRepository<ReleasedContent, UUID> {
    List<ReleasedContent> findByTenantIdAndClassId(String tenantId, UUID classId);
    List<ReleasedContent> findByTenantIdAndClassIdAndContentType(String tenantId, UUID classId, String contentType);
    List<ReleasedContent> findByTenantIdAndContentId(String tenantId, UUID contentId);
    boolean existsByTenantIdAndContentIdAndClassId(String tenantId, UUID contentId, UUID classId);
    Page<ReleasedContent> findByTenantIdOrderByReleasedAtDesc(String tenantId, Pageable pageable);
    Page<ReleasedContent> findByTenantIdAndReleasedByOrderByReleasedAtDesc(String tenantId, UUID releasedBy, Pageable pageable);
}
