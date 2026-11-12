package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/** JSON sent to the frontend for one occupancy reading. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OccupancyResponse {

    private UUID id;
    private String deviceId;          // thing name, e.g. "OCC_A"
    private String zoneName;
    private Integer occupancyCount;
    private Float distanceMm;         // null unless a distance sensor is used
    private OffsetDateTime recordedAt;

    public static OccupancyResponse from(com.energy.model.OccupancyReading reading) {
        return OccupancyResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDevice().getThingName())
            .zoneName(reading.getZone().getName())
            .occupancyCount(reading.getOccupancyCount())
            .distanceMm(reading.getDistanceMm())
            .recordedAt(reading.getRecordedAt())
            .build();
    }
}