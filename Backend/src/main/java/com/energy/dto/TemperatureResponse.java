package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * JSON sent to the frontend for one temperature reading.
 * Field names are unchanged from before, so the dashboard keeps working;
 * humidityPct is new (null for sensors without humidity).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TemperatureResponse {

    private UUID id;
    private String deviceId;          // the device's thing name, e.g. "TEMP_A"
    private String zoneName;
    private Float temperatureC;
    private Float humidityPct;
    private OffsetDateTime recordedAt;

    public static TemperatureResponse from(com.energy.model.TemperatureReading reading) {
        return TemperatureResponse.builder()
            .id(reading.getId())
            .deviceId(reading.getDevice().getThingName())
            .zoneName(reading.getZone().getName())
            .temperatureC(reading.getTemperatureC())
            .humidityPct(reading.getHumidityPct())
            .recordedAt(reading.getRecordedAt())
            .build();
    }
}