package com.energy.service;

import com.energy.dto.AnalyticsSnapshotResponse;
import com.energy.repository.AnalyticsSnapshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnalyticsSnapshotService {

    private final AnalyticsSnapshotRepository analyticsSnapshotRepository;

    private static final List<String> VALID_METRIC_TYPES =
        List.of("TEMP", "OCCUPANCY", "POWER", "HVAC");

    @Transactional(readOnly = true)
    public List<AnalyticsSnapshotResponse> getSnapshotsForZone(
        String zoneName,
        String metricType
    ) {
        validateMetricType(metricType);

        return analyticsSnapshotRepository
            .findByZoneNameAndMetricTypeOrderBySnapshotAtDesc(zoneName, metricType)
            .stream()
            .map(AnalyticsSnapshotResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AnalyticsSnapshotResponse> getSnapshotsForZoneBetween(
        String zoneName,
        String metricType,
        LocalDateTime from,
        LocalDateTime to
    ) {
        validateMetricType(metricType);

        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return analyticsSnapshotRepository
            .findByZoneNameAndMetricTypeAndSnapshotAtBetweenOrderBySnapshotAtDesc(
                zoneName, metricType, from, to
            )
            .stream()
            .map(AnalyticsSnapshotResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AnalyticsSnapshotResponse getLatestSnapshot(
        String zoneName,
        String metricType
    ) {
        validateMetricType(metricType);

        return analyticsSnapshotRepository
            .findTop1ByZoneNameAndMetricTypeOrderBySnapshotAtDesc(zoneName, metricType)
            .map(AnalyticsSnapshotResponse::from)
            .orElseThrow(() ->
                new RuntimeException(
                    "No analytics snapshots found for zone: "
                    + zoneName + ", metric: " + metricType
                )
            );
    }

    @Transactional(readOnly = true)
    public double getOverallAverage(
        String zoneName,
        String metricType,
        LocalDateTime from,
        LocalDateTime to
    ) {
        validateMetricType(metricType);

        return analyticsSnapshotRepository
            .findOverallAverage(zoneName, metricType, from, to)
            .orElse(0.0);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getZoneSummary(String zoneName) {
        Map<String, Object> summary = new HashMap<>();
        summary.put("zoneName", zoneName);

        for (String metricType : VALID_METRIC_TYPES) {
            analyticsSnapshotRepository
                .findTop1ByZoneNameAndMetricTypeOrderBySnapshotAtDesc(
                    zoneName, metricType
                )
                .ifPresent(snapshot ->
                    summary.put(metricType, AnalyticsSnapshotResponse.from(snapshot))
                );
        }

        return summary;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getAllZonesLatestSnapshot(String metricType) {
        validateMetricType(metricType);

        return analyticsSnapshotRepository
            .findLatestSummaryAllZones(metricType)
            .stream()
            .map(row -> buildSummaryFromRow(row, metricType))
            .collect(Collectors.toList());
    }

    private void validateMetricType(String metricType) {
        if (!VALID_METRIC_TYPES.contains(metricType)) {
            throw new RuntimeException(
                "Invalid metric type: '" + metricType
                + "'. Valid values: " + VALID_METRIC_TYPES
            );
        }
    }

    private Map<String, Object> buildSummaryFromRow(
        Object[] row,
        String metricType
    ) {
        return Map.of(
            "zoneName",    row[0],
            "metricType",  metricType,
            "meanVal",     row[1],
            "minVal",      row[2],
            "maxVal",      row[3],
            "sampleCount", row[4]
        );
    }

}