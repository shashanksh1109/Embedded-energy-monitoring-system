package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceResponse {

    private UUID id;
    private String deviceId;
    private String deviceType;
    private String zoneName;
    private Boolean useHardware;
    private Boolean isActive;
    private String description;
    private OffsetDateTime createdAt;

    public static DeviceResponse from(com.energy.model.Device device) {
        return DeviceResponse.builder()
            .id(device.getId())
            .deviceId(device.getDeviceId())
            .deviceType(device.getDeviceType())
            .zoneName(device.getZone().getName())
            .useHardware(device.getUseHardware())
            .isActive(device.getIsActive())
            .description(device.getDescription())
            .createdAt(device.getCreatedAt())
            .build();
    }
}
