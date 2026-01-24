package com.learning.role_permission_service.service;

import java.util.List;

import com.learning.role_permission_service.entity.AccessPolicyEntity;

public interface AccessPolicyService {
	AccessPolicyEntity createPolicy(Long tenantId, AccessPolicyEntity policy, String createdBy);

	AccessPolicyEntity updatePolicy(Long tenantId, Long policyId, AccessPolicyEntity policy);

	AccessPolicyEntity getPolicy(Long tenantId, Long policyId);

	List<AccessPolicyEntity> getPolicies(Long tenantId);

	void deletePolicy(Long tenantId, Long policyId);
}
