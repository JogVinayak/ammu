package com.learning.api_gateway.model.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MembershipActionRequest {
    private UUID actorId;
    private String reason;

}
