package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceResponse {

    private UUID id;
    private String deviceId;
    private String deviceType;
    private String zoneName;      // flattened from device.getZone().getName()
    private Boolean isActive;
    private LocalDateTime createdAt;

    public static DeviceResponse from(com.energy.model.Device device) {
        return DeviceResponse.builder()
            .id(device.getId())
            .deviceId(device.getDeviceId())
            .deviceType(device.getDeviceType())
            .zoneName(device.getZone().getName())  // unwrap Zone object → just the name
            .isActive(device.getIsActive())
            .createdAt(device.getCreatedAt())
            .build();
    }

}