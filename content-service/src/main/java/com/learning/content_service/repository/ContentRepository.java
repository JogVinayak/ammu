package com.learning.content_service.repository;

import com.learning.content_service.entity.Content;
import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import com.learning.content_service.enums.ContentVisibility;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ContentRepository extends JpaRepository<Content, UUID> {
    Optional<Content> findByIdAndTenantId(UUID id, String tenantId);

    Optional<Content> findByIdAndTenantIdAndDeletedFalse(UUID id, String tenantId);

    @Query(
            """
            select c from Content c
            where c.tenantId = :tenantId
              and c.deleted = false
              and (:type is null or c.type = :type)
              and (:status is null or c.status = :status)
              and (:topicId is null or c.topicId = :topicId)
              and (:moduleId is null or c.moduleId = :moduleId)
              and (:visibility is null or c.visibility = :visibility)
              and (:q is null or lower(c.title) like lower(concat('%', :q, '%'))
                   or lower(coalesce(c.description, '')) like lower(concat('%', :q, '%')))
            """)
    Page<Content> search(
            @Param("tenantId") String tenantId,
            @Param("type") ContentType type,
            @Param("status") ContentStatus status,
            @Param("topicId") UUID topicId,
            @Param("moduleId") UUID moduleId,
            @Param("visibility") ContentVisibility visibility,
            @Param("q") String q,
            Pageable pageable);
}
