package com.energy.controller;

import com.energy.dto.PowerReadingResponse;
import com.energy.service.PowerReadingService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/power")
@RequiredArgsConstructor
public class PowerReadingController {

    private final PowerReadingService powerReadingService;

    /**
     * GET /api/power/Zone_A
     *
     * Returns all power readings for a zone, newest first.
     */
    @GetMapping("/{zoneName}")
    public ResponseEntity<List<PowerReadingResponse>> getReadings(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(powerReadingService.getReadingsForZone(zoneName));
    }

    /**
     * GET /api/power/Zone_A/latest
     *
     * Returns the current power reading for a zone.
     * Used by dashboard to show live kW consumption.
     */
    @GetMapping("/{zoneName}/latest")
    public ResponseEntity<PowerReadingResponse> getLatest(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(powerReadingService.getLatestForZone(zoneName));
    }

    /**
     * GET /api/power/Zone_A/recent?hours=24
     *
     * Returns power readings from the last N hours.
     */
    @GetMapping("/{zoneName}/recent")
    public ResponseEntity<List<PowerReadingResponse>> getRecent(
        @PathVariable String zoneName,
        @RequestParam(required = false, defaultValue = "24") int hours
    ) {
        return ResponseEntity.ok(
            powerReadingService.getReadingsForLastHours(zoneName, hours)
        );
    }

    /**
     * GET /api/power/Zone_A/range?from=...&to=...
     *
     * Returns power readings within a specific time range.
     */
    @GetMapping("/{zoneName}/range")
    public ResponseEntity<List<PowerReadingResponse>> getRange(
        @PathVariable String zoneName,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return ResponseEntity.ok(
            powerReadingService.getReadingsForZoneBetween(zoneName, from, to)
        );
    }

    /**
     * GET /api/power/Zone_A/summary?from=...&to=...
     *
     * Returns energy and cost summary for a zone in a time range.
     *
     * Response:
     * {
     *   "zoneName":             "Zone_A",
     *   "energyConsumedKwh":    0.652,
     *   "totalCostUsd":         0.078,
     *   "peakPowerKw":          9.2,
     *   "avgPowerKw":           6.28,
     *   "projectedMonthlyCost": 543.17,
     *   "from":                 "2026-03-25T00:00:00",
     *   "to":                   "2026-03-25T23:59:59"
     * }
     */
    @GetMapping("/{zoneName}/summary")
    public ResponseEntity<Map<String, Object>> getEnergySummary(
        @PathVariable String zoneName,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return ResponseEntity.ok(
            powerReadingService.getEnergySummary(zoneName, from, to)
        );
    }

    /**
     * GET /api/power/Zone_A/sparkline
     *
     * Returns last 20 power readings for sparkline chart.
     */
    @GetMapping("/{zoneName}/sparkline")
    public ResponseEntity<List<PowerReadingResponse>> getSparkline(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(powerReadingService.getRecentReadings(zoneName));
    }

}