package com.learning.user_profile_service.service;

import com.learning.user_profile_service.model.dto.CreateUserRelationshipRequest;
import com.learning.user_profile_service.model.dto.UserRelationshipResponse;
import java.util.List;
import java.util.UUID;

public interface UserRelationshipService {
    UserRelationshipResponse createRelationship(UUID tenantId, CreateUserRelationshipRequest request, String actorId);

    List<UserRelationshipResponse> listRelationships(UUID tenantId, UUID userId);

    void deleteRelationship(UUID tenantId, UUID relationshipId);
}
