package com.learning.content_workflow_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Value("${services.user-profile.url:http://localhost:8083}")
    private String userProfileServiceUrl;

    @Value("${services.recall.url:http://localhost:8091}")
    private String recallServiceUrl;

    @Bean("userProfileRestClient")
    public RestClient userProfileRestClient() {
        return RestClient.builder()
                .baseUrl(userProfileServiceUrl)
                .build();
    }

    @Bean("recallRestClient")
    public RestClient recallRestClient() {
        return RestClient.builder()
                .baseUrl(recallServiceUrl)
                .build();
    }
}
