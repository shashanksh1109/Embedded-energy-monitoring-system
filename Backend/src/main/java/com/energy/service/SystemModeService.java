package com.energy.service;

import com.energy.model.SystemMode;
import com.energy.repository.SystemModeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.ecs.EcsClient;
import software.amazon.awssdk.services.ecs.model.UpdateServiceRequest;
import software.amazon.awssdk.services.ecs.model.DescribeServicesRequest;
import software.amazon.awssdk.services.ecs.model.DescribeServicesResponse;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

@Service
public class SystemModeService {

    @Autowired
    private SystemModeRepository repository;

    @Autowired
    private EcsClient ecsClient;

    @Value("${aws.ecs.cluster:energy-management-cluster}")
    private String clusterName;

    @Value("${aws.ecs.sensor-service:energy-management-sensor}")
    private String sensorService;

    // Get current mode
    public SystemMode getCurrentMode() {
        return repository.findById(1)
            .orElseGet(() -> {
                SystemMode m = new SystemMode();
                m.setId(1);
                m.setMode("SIMULATION");
                m.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));
                return repository.save(m);
            });
    }

    // Switch to simulation mode — start ECS sensor service
    public SystemMode setSimulationMode() {
        // Start sensor service (desired count = 1)
        ecsClient.updateService(UpdateServiceRequest.builder()
            .cluster(clusterName)
            .service(sensorService)
            .desiredCount(1)
            .build());

        return saveMode("SIMULATION");
    }

    // Switch to hardware mode — stop ECS sensor service
    public SystemMode setHardwareMode() {
        // Stop sensor service (desired count = 0)
        ecsClient.updateService(UpdateServiceRequest.builder()
            .cluster(clusterName)
            .service(sensorService)
            .desiredCount(0)
            .build());

        return saveMode("HARDWARE");
    }

    // Check if sensor service is actually running
    public boolean isSensorRunning() {
        DescribeServicesResponse response = ecsClient.describeServices(
            DescribeServicesRequest.builder()
                .cluster(clusterName)
                .services(sensorService)
                .build());

        if (response.services().isEmpty()) return false;

        return response.services().get(0).runningCount() > 0;
    }

    private SystemMode saveMode(String mode) {
        SystemMode current = getCurrentMode();
        current.setMode(mode);
        current.setUpdatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        return repository.save(current);
    }
}
