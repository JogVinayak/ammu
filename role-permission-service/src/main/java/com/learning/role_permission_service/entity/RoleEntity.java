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
@Table(name = "roles")
public class RoleEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "tenant_id", nullable = false)
	private Long tenantId;

	@Column(nullable = false)
	private String name;

	private String description;

	@Column(name = "is_system")
	private Boolean isSystem;

	private String status;

	@Column(name = "created_at")
	private Instant createdAt;

	@Column(name = "created_by")
	private String createdBy;

	@Column(name = "updated_at")
	private Instant updatedAt;

	@Column(name = "updated_by")
	private String updatedBy;
}
