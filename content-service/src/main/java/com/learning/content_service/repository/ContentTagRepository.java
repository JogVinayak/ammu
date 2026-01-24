package com.learning.content_service.repository;

import com.learning.content_service.entity.ContentTag;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentTagRepository extends JpaRepository<ContentTag, UUID> {
    List<ContentTag> findByTenantIdAndContentId(String tenantId, UUID contentId);

    List<ContentTag> findByTenantIdAndContentIdIn(String tenantId, Collection<UUID> contentIds);

    void deleteByTenantIdAndContentId(String tenantId, UUID contentId);
}
