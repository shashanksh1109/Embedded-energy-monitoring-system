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
public class OccupancyResponse {

    private UUID id;
    private String deviceId;
    private String zoneName;
    private Integer occupancyCount;
    private Float distanceMm;
    private LocalDateTime recordedAt;

    public static OccupancyResponse from(com.energy.model.OccupancyReading reading) {
        return OccupancyResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDeviceId())
            .zoneName(reading.getZone().getName())
            .occupancyCount(reading.getOccupancyCount())
            .distanceMm(reading.getDistanceMm())
            .recordedAt(reading.getRecordedAt())
            .build();
    }

}