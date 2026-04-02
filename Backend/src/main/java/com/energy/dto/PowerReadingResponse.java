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
public class PowerReadingResponse {

    private UUID id;
    private String deviceId;
    private String zoneName;
    private Float powerKw;
    private Float energyKwh;
    private Float costUsd;
    private OffsetDateTime recordedAt;

    public static PowerReadingResponse from(com.energy.model.PowerReading reading) {
        return PowerReadingResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDeviceId())
            .zoneName(reading.getZone().getName())
            .powerKw(reading.getPowerKw())
            .energyKwh(reading.getEnergyKwh())
            .costUsd(reading.getCostUsd())
            .recordedAt(reading.getRecordedAt())
            .build();
    }

}