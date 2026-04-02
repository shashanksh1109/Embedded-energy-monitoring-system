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
public class ZoneResponse {

    private UUID id;
    private String name;
    private String description;
    private Integer capacity;
    private LocalDateTime createdAt;

    // Converts Zone entity → ZoneResponse DTO
    public static ZoneResponse from(com.energy.model.Zone zone) {
        return ZoneResponse.builder()
            .id(zone.getId())
            .name(zone.getName())
            .description(zone.getDescription())
            .capacity(zone.getCapacity())
            .createdAt(zone.getCreatedAt())
            .build();
    }

}