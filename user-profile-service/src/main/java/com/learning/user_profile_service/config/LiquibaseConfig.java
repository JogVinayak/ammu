package com.learning.user_profile_service.config;

import javax.sql.DataSource;

import liquibase.integration.spring.SpringLiquibase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class LiquibaseConfig {
    @Bean
    public SpringLiquibase liquibase(
            DataSource dataSource,
            @Value("${spring.liquibase.change-log}") String changeLog,
            @Value("${spring.liquibase.default-schema:}") String defaultSchema,
            @Value("${spring.liquibase.contexts:}") String contexts,
            @Value("${spring.liquibase.drop-first:false}") boolean dropFirst,
            @Value("${spring.liquibase.enabled:true}") boolean enabled) {
        SpringLiquibase liquibase = new SpringLiquibase();
        liquibase.setDataSource(dataSource);
        liquibase.setChangeLog(changeLog);
        liquibase.setDropFirst(dropFirst);
        liquibase.setShouldRun(enabled);

        if (defaultSchema != null && !defaultSchema.isBlank()) {
            liquibase.setDefaultSchema(defaultSchema);
        }
        if (contexts != null && !contexts.isBlank()) {
            liquibase.setContexts(contexts);
        }

        return liquibase;
    }
}
