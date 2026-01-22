package com.learning.role_permission_service.model;

import java.time.Instant;

//how to fix lombok issues in visual studio code
// 1. Install the Lombok plugin for Visual Studio Code
// 2. Enable annotation processing in your IDE settings
// 3. Make sure your project is using a compatible version of Lombok

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Permission {
	private Long id;
	private String code;
	private String resource;
	private String action;
	private String description;
	private Boolean isDeprecated;
	private Instant createdAt;
}
