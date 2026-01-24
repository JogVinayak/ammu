package com.learning.api_gateway.controller;

import com.learning.api_gateway.model.dto.MembershipActionRequest;
import com.learning.api_gateway.model.dto.MembershipActionResponse;
import com.learning.api_gateway.service.TenantMembershipService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/tenants/{tenantId}/memberships/{membershipId}")
public class TenantMembershipController {
    private final TenantMembershipService tenantMembershipService;

    @PostMapping("/approve")
    public MembershipActionResponse approve(
            @PathVariable UUID tenantId,
            @PathVariable UUID membershipId,
            @RequestBody MembershipActionRequest request) {
        return tenantMembershipService.approve(tenantId, membershipId, request);
    }

    @PostMapping("/suspend")
    public MembershipActionResponse suspend(
            @PathVariable UUID tenantId,
            @PathVariable UUID membershipId,
            @RequestBody MembershipActionRequest request) {
        return tenantMembershipService.suspend(tenantId, membershipId, request);
    }
}
