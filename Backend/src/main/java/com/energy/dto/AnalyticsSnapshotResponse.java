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
public class AnalyticsSnapshotResponse {
    private UUID id;
    private String zoneName;
    private String metricType;
    private Float meanVal;
    private Float stddevVal;
    private Float minVal;
    private Float maxVal;
    private Integer sampleCount;
    private OffsetDateTime snapshotAt;
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
            .range(snapshot.getMaxVal() - snapshot.getMinVal())
            .build();
    }
}
