package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/** JSON sent to the frontend for one zone. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ZoneResponse {

    private UUID id;
    private UUID buildingId;
    private String name;
    private String description;
    private Integer capacity;
    private OffsetDateTime createdAt;

    public static ZoneResponse from(com.energy.model.Zone zone) {
        return ZoneResponse.builder()
            .id(zone.getId())
            // getId() on a lazy proxy does not load the building from the database
            .buildingId(zone.getBuilding() == null ? null : zone.getBuilding().getId())
            .name(zone.getName())
            .description(zone.getDescription())
            .capacity(zone.getCapacity())
            .createdAt(zone.getCreatedAt())
            .build();
    }
}