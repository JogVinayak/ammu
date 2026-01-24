package com.learning.auth_service.service;

import com.learning.auth_service.model.dto.MembershipActionRequest;
import com.learning.auth_service.model.dto.MembershipActionResponse;
import java.util.UUID;

public interface TenantMembershipService {
    MembershipActionResponse approve(UUID tenantId, UUID membershipId, MembershipActionRequest request);

    MembershipActionResponse suspend(UUID tenantId, UUID membershipId, MembershipActionRequest request);
}
