package com.learning.role_permission_service.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "access_policies")
public class AccessPolicyEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "tenant_id", nullable = false, length = 36)
	private String tenantId;

	@Column(nullable = false)
	private String name;

	private String effect;

	private Integer priority;

	private String resource;

	private String action;

	@Lob
	@Column(name = "condition_json")
	private String conditionJson;

	private String status;

	@Column(name = "created_at")
	private Instant createdAt;

	@Column(name = "created_by")
	private String createdBy;
}
