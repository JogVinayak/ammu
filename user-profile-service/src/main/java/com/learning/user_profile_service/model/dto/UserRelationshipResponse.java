package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.RelationshipType;
import java.time.Instant;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UserRelationshipResponse {
    private UUID id;
    private UUID tenantId;
    private UUID userId;
    private UUID relatedUserId;
    private RelationshipType relationshipType;
    private Instant createdAt;
}
