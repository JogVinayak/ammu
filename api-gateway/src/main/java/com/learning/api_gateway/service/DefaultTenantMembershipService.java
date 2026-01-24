package com.learning.api_gateway.service;

import com.learning.api_gateway.model.dto.MembershipActionRequest;
import com.learning.api_gateway.model.dto.MembershipActionResponse;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@RequiredArgsConstructor
@Service
public class DefaultTenantMembershipService implements TenantMembershipService {
    private final RestClient authServiceClient;

    @Override
    public MembershipActionResponse approve(UUID tenantId, UUID membershipId, MembershipActionRequest request) {
        return authServiceClient.post()
                .uri("/tenants/{tenantId}/memberships/{membershipId}/approve", tenantId, membershipId)
                .body(request)
                .retrieve()
                .body(MembershipActionResponse.class);
    }

    @Override
    public MembershipActionResponse suspend(UUID tenantId, UUID membershipId, MembershipActionRequest request) {
        return authServiceClient.post()
                .uri("/tenants/{tenantId}/memberships/{membershipId}/suspend", tenantId, membershipId)
                .body(request)
                .retrieve()
                .body(MembershipActionResponse.class);
    }
}
