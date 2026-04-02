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
public class AnalyticsSnapshotResponse {

    private UUID id;
    private String zoneName;
    private String metricType;
    private Float meanVal;
    private Float stddevVal;
    private Float minVal;
    private Float maxVal;
    private Integer sampleCount;
    private LocalDateTime snapshotAt;

    // Computed field — max minus min, shows spread of values in this window
    // Not stored in DB — calculated during mapping
    // e.g. min=17.4, max=24.5 → range=7.1
    private Float range;

    public static AnalyticsSnapshotResponse from(com.energy.model.AnalyticsSnapshot snapshot) {
        return AnalyticsSnapshotResponse.builder()
            .id(snapshot.getId())
            .zoneName(snapshot.getZone().getName())
            .metricType(snapshot.getMetricType())
            .meanVal(snapshot.getMeanVal())
            .stddevVal(snapshot.getStddevVal())
            .minVal(snapshot.getMinVal())
            .maxVal(snapshot.getMaxVal())
            .sampleCount(snapshot.getSampleCount())
            .snapshotAt(snapshot.getSnapshotAt())
            .range(snapshot.getMaxVal() - snapshot.getMinVal())  // computed here
            .build();
    }

}