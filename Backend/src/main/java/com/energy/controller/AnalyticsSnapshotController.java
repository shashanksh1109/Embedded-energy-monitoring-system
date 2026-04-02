package com.energy.controller;

import com.energy.dto.AnalyticsSnapshotResponse;
import com.energy.service.AnalyticsSnapshotService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsSnapshotController {

    private final AnalyticsSnapshotService analyticsSnapshotService;

    /**
     * GET /api/analytics/Zone_A?metric=TEMP
     *
     * Returns all snapshots for a zone and metric type.
     *
     * Notice metric comes from @RequestParam not @PathVariable.
     * It's a filter on the data, not part of the resource identity.
     * Good REST design — the resource is "analytics for Zone_A",
     * the metric type is a filter on that resource.
     */
    @GetMapping("/{zoneName}")
    public ResponseEntity<List<AnalyticsSnapshotResponse>> getSnapshots(
        @PathVariable String zoneName,
        @RequestParam String metric
    ) {
        return ResponseEntity.ok(
            analyticsSnapshotService.getSnapshotsForZone(zoneName, metric)
        );
    }

    /**
     * GET /api/analytics/Zone_A/latest?metric=TEMP
     *
     * Returns the most recent snapshot for a zone and metric.
     * Used by dashboard summary cards:
     *   "Last 60s — avg: 21.4°C  stddev: 0.8  samples: 12"
     */
    @GetMapping("/{zoneName}/latest")
    public ResponseEntity<AnalyticsSnapshotResponse> getLatest(
        @PathVariable String zoneName,
        @RequestParam String metric
    ) {
        return ResponseEntity.ok(
            analyticsSnapshotService.getLatestSnapshot(zoneName, metric)
        );
    }

    /**
     * GET /api/analytics/Zone_A/range?metric=TEMP&from=...&to=...
     *
     * Returns snapshots for a zone, metric, and time range.
     * Used by analytics history charts on dashboard.
     */
    @GetMapping("/{zoneName}/range")
    public ResponseEntity<List<AnalyticsSnapshotResponse>> getRange(
        @PathVariable String zoneName,
        @RequestParam String metric,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return ResponseEntity.ok(
            analyticsSnapshotService.getSnapshotsForZoneBetween(zoneName, metric, from, to)
        );
    }

    /**
     * GET /api/analytics/Zone_A/average?metric=TEMP&from=...&to=...
     *
     * Returns overall average for a zone and metric in a range.
     * Returns a plain number wrapped in a Map with context.
     *
     * Response:
     * {
     *   "zoneName":  "Zone_A",
     *   "metric":    "TEMP",
     *   "average":   21.45,
     *   "from":      "2026-03-25T00:00:00",
     *   "to":        "2026-03-25T23:59:59"
     * }
     */
    @GetMapping("/{zoneName}/average")
    public ResponseEntity<Map<String, Object>> getAverage(
        @PathVariable String zoneName,
        @RequestParam String metric,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        double average = analyticsSnapshotService.getOverallAverage(
            zoneName, metric, from, to
        );
        return ResponseEntity.ok(Map.of(
            "zoneName", zoneName,
            "metric",   metric,
            "average",  average,
            "from",     from,
            "to",       to
        ));
    }

    /**
     * GET /api/analytics/Zone_A/summary
     *
     * Returns latest snapshot for all four metric types at once.
     * Used by zone detail page — one call for full picture.
     *
     * Response:
     * {
     *   "zoneName":  "Zone_A",
     *   "TEMP":      { "meanVal": 21.4, "stddevVal": 0.8, ... },
     *   "OCCUPANCY": { "meanVal": 2.75, "stddevVal": 1.48, ... },
     *   "POWER":     { "meanVal": 6.28, "stddevVal": 2.91, ... },
     *   "HVAC":      { "meanVal": 38.5, "stddevVal": 25.1, ... }
     * }
     */
    @GetMapping("/{zoneName}/summary")
    public ResponseEntity<Map<String, Object>> getZoneSummary(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(
            analyticsSnapshotService.getZoneSummary(zoneName)
        );
    }

    /**
     * GET /api/analytics/all?metric=TEMP
     *
     * Returns latest snapshot for every zone for a given metric.
     * Used by dashboard overview — compare all zones side by side.
     *
     * Notice this endpoint has no {zoneName} in the path.
     * "all" is hardcoded — it returns data for all zones at once.
     *
     * Response:
     * [
     *   { "zoneName": "Zone_A", "meanVal": 21.4, ... },
     *   { "zoneName": "Zone_B", "meanVal": 20.1, ... },
     *   { "zoneName": "Zone_C", "meanVal": 18.2, ... }
     * ]
     */
    @GetMapping("/all")
    public ResponseEntity<List<Map<String, Object>>> getAllZonesLatest(
        @RequestParam String metric
    ) {
        return ResponseEntity.ok(
            analyticsSnapshotService.getAllZonesLatestSnapshot(metric)
        );
    }

}