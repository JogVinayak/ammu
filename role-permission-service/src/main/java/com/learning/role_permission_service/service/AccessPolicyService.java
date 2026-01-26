package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.entity.AccessPolicyEntity;

public interface AccessPolicyService {
	AccessPolicyEntity createPolicy(String tenantId, AccessPolicyEntity policy, String createdBy);

	AccessPolicyEntity updatePolicy(String tenantId, Long policyId, AccessPolicyEntity policy);

	AccessPolicyEntity getPolicy(String tenantId, Long policyId);

	List<AccessPolicyEntity> getPolicies(String tenantId);

	void deletePolicy(String tenantId, Long policyId);
}
