package com.learning.role_permission_service.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.learning.role_permission_service.dto.AccessPolicyRequest;
import com.learning.role_permission_service.dto.AccessPolicyResponse;
import com.learning.role_permission_service.entity.AccessPolicyEntity;
import com.learning.role_permission_service.service.AccessPolicyService;

@RestController
@RequestMapping("/tenants/{tenantId}/policies")
public class AccessPolicyController {
	private final AccessPolicyService policyService;

	public AccessPolicyController(AccessPolicyService policyService) {
		this.policyService = policyService;
	}

	@PostMapping
	public AccessPolicyResponse createPolicy(
			@PathVariable Long tenantId,
			@RequestBody AccessPolicyRequest request,
			@RequestHeader(value = "X-User-Id", required = false) String userId) {
		AccessPolicyEntity policy = new AccessPolicyEntity();
		policy.setName(request.getName());
		policy.setEffect(request.getEffect());
		policy.setPriority(request.getPriority());
		policy.setResource(request.getResource());
		policy.setAction(request.getAction());
		policy.setConditionJson(request.getConditionJson());
		policy.setStatus(request.getStatus());
		return toResponse(policyService.createPolicy(tenantId, policy, userId));
	}

	@PutMapping("/{policyId}")
	public AccessPolicyResponse updatePolicy(
			@PathVariable Long tenantId,
			@PathVariable Long policyId,
			@RequestBody AccessPolicyRequest request) {
		AccessPolicyEntity policy = new AccessPolicyEntity();
		policy.setName(request.getName());
		policy.setEffect(request.getEffect());
		policy.setPriority(request.getPriority());
		policy.setResource(request.getResource());
		policy.setAction(request.getAction());
		policy.setConditionJson(request.getConditionJson());
		policy.setStatus(request.getStatus());
		return toResponse(policyService.updatePolicy(tenantId, policyId, policy));
	}

	@GetMapping("/{policyId}")
	public AccessPolicyResponse getPolicy(@PathVariable Long tenantId, @PathVariable Long policyId) {
		return toResponse(policyService.getPolicy(tenantId, policyId));
	}

	@GetMapping
	public List<AccessPolicyResponse> getPolicies(@PathVariable Long tenantId) {
		return policyService.getPolicies(tenantId).stream().map(this::toResponse).toList();
	}

	@DeleteMapping("/{policyId}")
	public void deletePolicy(@PathVariable Long tenantId, @PathVariable Long policyId) {
		policyService.deletePolicy(tenantId, policyId);
	}

	private AccessPolicyResponse toResponse(AccessPolicyEntity policy) {
		return new AccessPolicyResponse(
				policy.getId(),
				policy.getTenantId(),
				policy.getName(),
				policy.getEffect(),
				policy.getPriority(),
				policy.getResource(),
				policy.getAction(),
				policy.getConditionJson(),
				policy.getStatus(),
				policy.getCreatedAt(),
				policy.getCreatedBy());
	}
}
