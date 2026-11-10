package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * JSON sent to the frontend for one HVAC state.
 * "mode" is derived here so the dashboard doesn't have to compare percentages.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HvacStateResponse {

    private UUID id;
    private String deviceId;          // thing name, e.g. "HVAC_A"
    private String zoneName;
    private Float heaterPct;
    private Float coolerPct;
    private Float currentTemp;
    private Float setpoint;
    private OffsetDateTime recordedAt;

    /** "HEATING", "COOLING" or "IDLE" */
    private String mode;

    public static HvacStateResponse from(com.energy.model.HvacState state) {
        String mode;
        if (state.getHeaterPct() > 0) {
            mode = "HEATING";
        } else if (state.getCoolerPct() > 0) {
            mode = "COOLING";
        } else {
            mode = "IDLE";
        }

        return HvacStateResponse.builder()
            .id(state.getId())
            .deviceId(state.getDevice().getThingName())
            .zoneName(state.getZone().getName())
            .heaterPct(state.getHeaterPct())
            .coolerPct(state.getCoolerPct())
            .currentTemp(state.getCurrentTemp())
            .setpoint(state.getSetpoint())
            .recordedAt(state.getRecordedAt())
            .mode(mode)
            .build();
    }
}