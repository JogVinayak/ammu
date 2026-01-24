package com.learning.api_gateway.service;

import com.learning.api_gateway.model.dto.MembershipActionRequest;
import com.learning.api_gateway.model.dto.MembershipActionResponse;
import java.util.UUID;

public interface TenantMembershipService {
    MembershipActionResponse approve(UUID tenantId, UUID membershipId, MembershipActionRequest request);

    MembershipActionResponse suspend(UUID tenantId, UUID membershipId, MembershipActionRequest request);
}
