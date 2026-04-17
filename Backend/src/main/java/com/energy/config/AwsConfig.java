package com.energy.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.ecs.EcsClient;

@Configuration
public class AwsConfig {

    @Bean
    public EcsClient ecsClient() {
        // When running on ECS, credentials come automatically
        // from the task role we attached in Terraform
        return EcsClient.builder()
            .region(Region.US_EAST_1)
            .build();
    }
}
