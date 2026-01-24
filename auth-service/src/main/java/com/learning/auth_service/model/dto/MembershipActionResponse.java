package com.learning.auth_service.model.dto;

import com.learning.auth_service.model.enums.TenantMembershipStatus;
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
