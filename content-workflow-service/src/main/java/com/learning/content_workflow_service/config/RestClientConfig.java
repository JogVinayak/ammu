package com.learning.content_workflow_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Value("${services.user-profile.url:http://localhost:8083}")
    private String userProfileServiceUrl;

    @Bean("userProfileRestClient")
    public RestClient userProfileRestClient() {
        return RestClient.builder()
                .baseUrl(userProfileServiceUrl)
                .build();
    }
}
