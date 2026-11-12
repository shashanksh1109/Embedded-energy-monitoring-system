package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * JSON sent to the frontend for one power reading.
 *
 * The database now stores watts and per-interval energy (power_w, energy_wh).
 * This DTO still reports powerKw, energyKwh and costUsd, so the frontend
 * needs no changes. powerW is added for anyone who wants watts.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PowerReadingResponse {

    /** Electricity price used for cost estimates (USD per kWh). One place to change it. */
    public static final float COST_PER_KWH = 0.12f;

    private UUID id;
    private String deviceId;          // thing name, e.g. "POWER_A"
    private String zoneName;
    private Float powerW;
    private Float powerKw;
    private Float energyKwh;          // energy used during THIS reading's interval
    private Float costUsd;            // cost of THIS reading's interval
    private OffsetDateTime recordedAt;

    public static PowerReadingResponse from(com.energy.model.PowerReading reading) {
        Float energyKwh = reading.getEnergyKwh();
        return PowerReadingResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDevice().getThingName())
            .zoneName(reading.getZone().getName())
            .powerW(reading.getPowerW())
            .powerKw(reading.getPowerKw())
            .energyKwh(energyKwh)
            .costUsd(energyKwh == null ? null : energyKwh * COST_PER_KWH)
            .recordedAt(reading.getRecordedAt())
            .build();
    }
}