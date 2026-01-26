package com.learning.role_permission_service.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "user_role_assignments")
public class UserRoleAssignmentEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "tenant_id", nullable = false, length = 36)
	private String tenantId;

	@Column(name = "user_id", nullable = false, length = 36)
	private String userId;

	@Column(name = "role_id", nullable = false)
	private Long roleId;

	@Column(name = "scope_type")
	private String scopeType;

	@Column(name = "scope_id")
	private String scopeId;

	private String status;

	@Column(name = "valid_from")
	private Instant validFrom;

	@Column(name = "valid_to")
	private Instant validTo;

	@Column(name = "assigned_by")
	private String assignedBy;

	@Column(name = "created_at")
	private Instant createdAt;
}
