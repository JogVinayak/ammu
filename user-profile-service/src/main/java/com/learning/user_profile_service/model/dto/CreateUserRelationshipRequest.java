package com.learning.user_profile_service.model.dto;

import com.learning.user_profile_service.model.enums.RelationshipType;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class CreateUserRelationshipRequest {
    @NotNull
    private UUID userId;

    @NotNull
    private UUID relatedUserId;

    @NotNull
    private RelationshipType relationshipType;
}
