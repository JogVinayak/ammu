package com.learning.auth_service.service;

import com.learning.auth_service.model.dto.MembershipActionRequest;
import com.learning.auth_service.model.dto.MembershipActionResponse;
import com.learning.auth_service.model.enums.TenantMembershipStatus;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class DefaultTenantMembershipService implements TenantMembershipService {
    @Override
    public MembershipActionResponse approve(UUID tenantId, UUID membershipId, MembershipActionRequest request) {
        MembershipActionResponse response = new MembershipActionResponse();
        response.setMembershipId(membershipId);
        response.setStatus(TenantMembershipStatus.ACTIVE);
        return response;
    }

    @Override
    public MembershipActionResponse suspend(UUID tenantId, UUID membershipId, MembershipActionRequest request) {
        MembershipActionResponse response = new MembershipActionResponse();
        response.setMembershipId(membershipId);
        response.setStatus(TenantMembershipStatus.SUSPENDED);
        return response;
    }
}
