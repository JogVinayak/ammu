package com.learning.content_service.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "content_tags",
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_content_tag",
                    columnNames = {"tenant_id", "content_id", "tag"})
        })
@Getter
@Setter
@NoArgsConstructor
public class ContentTag {
    @Id
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "content_id", nullable = false)
    private UUID contentId;

    @Column(nullable = false, length = 50)
    private String tag;
}
