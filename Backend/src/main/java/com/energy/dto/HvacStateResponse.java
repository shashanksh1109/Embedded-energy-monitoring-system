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
public class HvacStateResponse {

    private UUID id;
    private String deviceId;
    private String zoneName;
    private Float heaterPct;
    private Float coolerPct;
    private Float currentTemp;
    private Float setpoint;
    private OffsetDateTime recordedAt;

    // Convenience field — tells the dashboard at a glance
    // what mode the HVAC is in without checking both percentages
    // "HEATING", "COOLING", or "IDLE"
    private String mode;

    public static HvacStateResponse from(com.energy.model.HvacState state) {
        // Determine mode from heater/cooler values
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
            .deviceId(state.getDeviceId())
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