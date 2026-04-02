package com.energy.controller;

import com.energy.dto.HvacStateResponse;
import com.energy.service.HvacStateService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/hvac")
@RequiredArgsConstructor
public class HvacStateController {

    private final HvacStateService hvacStateService;

    /**
     * GET /api/hvac/Zone_A
     *
     * Returns all HVAC states for a zone, newest first.
     */
    @GetMapping("/{zoneName}")
    public ResponseEntity<List<HvacStateResponse>> getStates(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(hvacStateService.getStatesForZone(zoneName));
    }

    /**
     * GET /api/hvac/Zone_A/latest
     *
     * Returns the current HVAC state for a zone.
     * Used by dashboard to show heater%, cooler%, mode.
     */
    @GetMapping("/{zoneName}/latest")
    public ResponseEntity<HvacStateResponse> getLatest(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(hvacStateService.getLatestForZone(zoneName));
    }

    /**
     * GET /api/hvac/Zone_A/mode
     *
     * Returns the current HVAC mode as a simple string.
     * Used by dashboard status badge — "HEATING", "COOLING", "IDLE"
     *
     * Response:
     * {
     *   "zoneName": "Zone_A",
     *   "mode": "HEATING"
     * }
     */
    @GetMapping("/{zoneName}/mode")
    public ResponseEntity<Map<String, Object>> getCurrentMode(
        @PathVariable String zoneName
    ) {
        String mode = hvacStateService.getCurrentMode(zoneName);
        return ResponseEntity.ok(Map.of(
            "zoneName", zoneName,
            "mode",     mode
        ));
    }

    /**
     * GET /api/hvac/Zone_A/recent?hours=24
     *
     * Returns HVAC states from the last N hours.
     */
    @GetMapping("/{zoneName}/recent")
    public ResponseEntity<List<HvacStateResponse>> getRecent(
        @PathVariable String zoneName,
        @RequestParam(required = false, defaultValue = "24") int hours
    ) {
        return ResponseEntity.ok(
            hvacStateService.getStatesForLastHours(zoneName, hours)
        );
    }

    /**
     * GET /api/hvac/Zone_A/range?from=...&to=...
     *
     * Returns HVAC states within a specific time range.
     */
    @GetMapping("/{zoneName}/range")
    public ResponseEntity<List<HvacStateResponse>> getRange(
        @PathVariable String zoneName,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to
    ) {
        return ResponseEntity.ok(
            hvacStateService.getStatesForZoneBetween(zoneName, from, to)
        );
    }

    /**
     * GET /api/hvac/Zone_A/summary?from=...&to=...
     *
     * Returns HVAC usage summary for a zone in a time range.
     * Service returns a Map — controller passes it straight through.
     *
     * Response:
     * {
     *   "zoneName":        "Zone_A",
     *   "avgHeaterPct":    42.5,
     *   "avgCoolerPct":    12.3,
     *   "heatingReadings": 245,
     *   "coolingReadings": 87,
     *   "from":            "2026-03-25T00:00:00",
     *   "to":              "2026-03-25T23:59:59"
     * }
     */
    @GetMapping("/{zoneName}/summary")
    public ResponseEntity<Map<String, Object>> getUsageSummary(
        @PathVariable String zoneName,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to
    ) {
        return ResponseEntity.ok(
            hvacStateService.getUsageSummary(zoneName, from, to)
        );
    }

    /**
     * GET /api/hvac/Zone_A/sparkline
     *
     * Returns last 20 HVAC states for sparkline chart.
     */
    @GetMapping("/{zoneName}/sparkline")
    public ResponseEntity<List<HvacStateResponse>> getSparkline(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(hvacStateService.getRecentStates(zoneName));
    }

}