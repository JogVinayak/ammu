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
@Table(name = "role_permission_grants")
public class RolePermissionGrantEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "tenant_id", nullable = false)
	private Long tenantId;

	@Column(name = "role_id", nullable = false)
	private Long roleId;

	@Column(name = "permission_code", nullable = false)
	private String permissionCode;

	@Column(name = "scope_code")
	private String scopeCode;

	@Lob
	@Column(name = "constraints_json")
	private String constraintsJson;

	@Column(name = "created_at")
	private Instant createdAt;

	@Column(name = "created_by")
	private String createdBy;
}
