package com.learning.api_gateway.model.dto;

import com.learning.api_gateway.model.enums.TenantMembershipStatus;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MembershipActionResponse {
    private UUID membershipId;
    private TenantMembershipStatus status;

}
