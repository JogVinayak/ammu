package com.learning.role_permission_service.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenApiConfig {
	@Bean
	public OpenAPI rolePermissionOpenApi() {
		return new OpenAPI()
				.info(new Info()
						.title("Role Permission Service API")
						.description("API documentation for role-permission-service")
						.version("v1"));
	}
}
