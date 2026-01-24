package com.learning.user_profile_service.service;

import com.learning.user_profile_service.exception.ResourceNotFoundException;
import com.learning.user_profile_service.model.dto.CreateUserRelationshipRequest;
import com.learning.user_profile_service.model.dto.UserRelationshipResponse;
import com.learning.user_profile_service.model.entity.UserRelationship;
import com.learning.user_profile_service.repository.UserRelationshipRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultUserRelationshipService implements UserRelationshipService {
    private final UserRelationshipRepository relationshipRepository;

    public DefaultUserRelationshipService(UserRelationshipRepository relationshipRepository) {
        this.relationshipRepository = relationshipRepository;
    }

    @Override
    @Transactional
    public UserRelationshipResponse createRelationship(UUID tenantId, CreateUserRelationshipRequest request,
            String actorId) {
        boolean exists = relationshipRepository.existsByTenantIdAndUserIdAndRelatedUserIdAndRelationshipType(
                tenantId,
                request.getUserId(),
                request.getRelatedUserId(),
                request.getRelationshipType());
        if (exists) {
            throw new IllegalStateException("Relationship already exists");
        }

        UserRelationship relationship = new UserRelationship();
        relationship.setId(UUID.randomUUID());
        relationship.setTenantId(tenantId);
        relationship.setUserId(request.getUserId());
        relationship.setRelatedUserId(request.getRelatedUserId());
        relationship.setRelationshipType(request.getRelationshipType());
        relationship.setCreatedAt(Instant.now());
        relationship.setCreatedBy(actorId);
        return toResponse(relationshipRepository.save(relationship));
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserRelationshipResponse> listRelationships(UUID tenantId, UUID userId) {
        return relationshipRepository.findByTenantIdAndUserId(tenantId, userId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public void deleteRelationship(UUID tenantId, UUID relationshipId) {
        UserRelationship relationship = relationshipRepository.findByTenantIdAndId(tenantId, relationshipId)
                .orElseThrow(() -> new ResourceNotFoundException("Relationship not found"));
        relationshipRepository.delete(relationship);
    }

    private UserRelationshipResponse toResponse(UserRelationship relationship) {
        UserRelationshipResponse response = new UserRelationshipResponse();
        response.setId(relationship.getId());
        response.setTenantId(relationship.getTenantId());
        response.setUserId(relationship.getUserId());
        response.setRelatedUserId(relationship.getRelatedUserId());
        response.setRelationshipType(relationship.getRelationshipType());
        response.setCreatedAt(relationship.getCreatedAt());
        return response;
    }
}
