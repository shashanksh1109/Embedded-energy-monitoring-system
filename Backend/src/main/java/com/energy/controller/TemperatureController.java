package com.energy.controller;

import com.energy.dto.TemperatureResponse;
import com.energy.service.TemperatureService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/temperature")
@RequiredArgsConstructor
public class TemperatureController {

    private final TemperatureService temperatureService;

    /**
     * GET /api/temperature/Zone_A
     *
     * Returns all readings for a zone, newest first.
     */
    @GetMapping("/{zoneName}")
    public ResponseEntity<List<TemperatureResponse>> getReadings(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(temperatureService.getReadingsForZone(zoneName));
    }

    /**
     * GET /api/temperature/Zone_A/latest
     *
     * Returns the single most recent reading for a zone.
     * Used by live dashboard temperature card.
     *
     * Notice "latest" is hardcoded in the path — not a variable.
     * Spring matches this before trying /{zoneName} above
     * because specific paths take priority over variable paths.
     */
    @GetMapping("/{zoneName}/latest")
    public ResponseEntity<TemperatureResponse> getLatest(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(temperatureService.getLatestForZone(zoneName));
    }

    /**
     * GET /api/temperature/Zone_A/recent?hours=24
     *
     * Returns readings from the last N hours.
     *
     * @RequestParam extracts query parameters — the key=value
     * pairs that come after ? in a URL.
     *
     * required = false → parameter is optional
     * defaultValue = "24" → if not provided, default to 24 hours
     *
     * Examples:
     *   /api/temperature/Zone_A/recent          → last 24 hours (default)
     *   /api/temperature/Zone_A/recent?hours=1  → last 1 hour
     *   /api/temperature/Zone_A/recent?hours=48 → last 48 hours
     */
    @GetMapping("/{zoneName}/recent")
    public ResponseEntity<List<TemperatureResponse>> getRecent(
        @PathVariable String zoneName,
        @RequestParam(required = false, defaultValue = "24") int hours
    ) {
        return ResponseEntity.ok(
            temperatureService.getReadingsForLastHours(zoneName, hours)
        );
    }

    /**
     * GET /api/temperature/Zone_A/range?from=2026-03-25T00:00:00&to=2026-03-25T23:59:59
     *
     * Returns readings within a specific time range.
     *
     * @RequestParam with @DateTimeFormat:
     *   The URL contains a date string like "2026-03-25T00:00:00"
     *   Spring needs to know how to parse that string into
     *   a LocalDateTime Java object.
     *
     *   @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
     *   tells Spring to expect ISO 8601 format: yyyy-MM-ddTHH:mm:ss
     *
     * Both from and to are required here — no default makes sense
     * for an explicit range query.
     */
    @GetMapping("/{zoneName}/range")
    public ResponseEntity<List<TemperatureResponse>> getRange(
        @PathVariable String zoneName,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to
    ) {
        return ResponseEntity.ok(
            temperatureService.getReadingsForZoneBetween(zoneName, from, to)
        );
    }

    /**
     * GET /api/temperature/Zone_A/alerts
     *
     * Returns all readings where temperature dropped below 18°C.
     * Used by dashboard alert history page.
     *
     * No parameters needed — threshold is defined in the service.
     */
    @GetMapping("/{zoneName}/alerts")
    public ResponseEntity<List<TemperatureResponse>> getLowTemperatureAlerts(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(
            temperatureService.getLowTemperatureAlerts(zoneName)
        );
    }

    /**
     * GET /api/temperature/Zone_A/sparkline
     *
     * Returns last 20 readings for sparkline chart.
     * Used by dashboard zone cards — small trend indicator.
     */
    @GetMapping("/{zoneName}/sparkline")
    public ResponseEntity<List<TemperatureResponse>> getSparkline(
        @PathVariable String zoneName
    ) {
        return ResponseEntity.ok(temperatureService.getRecentReadings(zoneName));
    }

}