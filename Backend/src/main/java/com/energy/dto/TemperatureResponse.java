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
public class TemperatureResponse {

    private UUID id;
    private String deviceId;
    private String zoneName;
    private Float temperatureC;
    private LocalDateTime recordedAt;

    public static TemperatureResponse from(com.energy.model.TemperatureReading reading) {
        return TemperatureResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDeviceId())
            .zoneName(reading.getZone().getName())
            .temperatureC(reading.getTemperatureC())
            .recordedAt(reading.getRecordedAt())
            .build();
    }

}