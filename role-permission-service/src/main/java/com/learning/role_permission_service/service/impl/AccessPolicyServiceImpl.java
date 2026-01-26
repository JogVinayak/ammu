package com.learning.role_permission_service.service.impl;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.learning.role_permission_service.entity.AccessPolicyEntity;
import com.learning.role_permission_service.exception.ResourceNotFoundException;
import com.learning.role_permission_service.repository.AccessPolicyRepository;
import com.learning.role_permission_service.service.AccessPolicyService;

@Service
public class AccessPolicyServiceImpl implements AccessPolicyService {
	private final AccessPolicyRepository policyRepository;

	public AccessPolicyServiceImpl(AccessPolicyRepository policyRepository) {
		this.policyRepository = policyRepository;
	}

	@Override
	@Transactional
	public AccessPolicyEntity createPolicy(String tenantId, AccessPolicyEntity policy, String createdBy) {
		AccessPolicyEntity entity = new AccessPolicyEntity();
		entity.setTenantId(tenantId);
		entity.setName(policy.getName());
		entity.setEffect(policy.getEffect());
		entity.setPriority(policy.getPriority());
		entity.setResource(policy.getResource());
		entity.setAction(policy.getAction());
		entity.setConditionJson(policy.getConditionJson());
		entity.setStatus(policy.getStatus());
		entity.setCreatedAt(Instant.now());
		entity.setCreatedBy(createdBy);
		return policyRepository.save(entity);
	}

	@Override
	@Transactional
	public AccessPolicyEntity updatePolicy(String tenantId, Long policyId, AccessPolicyEntity policy) {
		AccessPolicyEntity existing = getPolicy(tenantId, policyId);
		existing.setName(policy.getName());
		existing.setEffect(policy.getEffect());
		existing.setPriority(policy.getPriority());
		existing.setResource(policy.getResource());
		existing.setAction(policy.getAction());
		existing.setConditionJson(policy.getConditionJson());
		existing.setStatus(policy.getStatus());
		return policyRepository.save(existing);
	}

	@Override
	@Transactional(readOnly = true)
	public AccessPolicyEntity getPolicy(String tenantId, Long policyId) {
		return policyRepository.findByIdAndTenantId(policyId, tenantId)
				.orElseThrow(() -> new ResourceNotFoundException("Policy not found"));
	}

	@Override
	@Transactional(readOnly = true)
	public List<AccessPolicyEntity> getPolicies(String tenantId) {
		return policyRepository.findByTenantId(tenantId);
	}

	@Override
	@Transactional
	public void deletePolicy(String tenantId, Long policyId) {
		policyRepository.delete(getPolicy(tenantId, policyId));
	}
}
