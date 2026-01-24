package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.CreateUserRelationshipRequest;
import com.learning.user_profile_service.model.dto.UserRelationshipResponse;
import com.learning.user_profile_service.service.UserRelationshipService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/relationships")
public class UserRelationshipController {
    private final UserRelationshipService relationshipService;

    @PostMapping
    public UserRelationshipResponse createRelationship(
            @PathVariable UUID tenantId,
            @Valid @RequestBody CreateUserRelationshipRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String actorId) {
        return relationshipService.createRelationship(tenantId, request, actorId);
    }

    @GetMapping("/users/{userId}")
    public List<UserRelationshipResponse> listRelationships(
            @PathVariable UUID tenantId,
            @PathVariable UUID userId) {
        return relationshipService.listRelationships(tenantId, userId);
    }

    @DeleteMapping("/{relationshipId}")
    public void deleteRelationship(@PathVariable UUID tenantId, @PathVariable UUID relationshipId) {
        relationshipService.deleteRelationship(tenantId, relationshipId);
    }
}
