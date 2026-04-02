package com.energy.service;

import com.energy.dto.TemperatureResponse;
import com.energy.repository.TemperatureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TemperatureService {

    private final TemperatureRepository temperatureRepository;

    // Default threshold used for low temperature alerts
    // Matches the orchestration config in your Python gateway
    private static final float LOW_TEMP_THRESHOLD = 18.0f;

    /**
     * Get all readings for a zone, newest first.
     * Used by temperature history page on dashboard.
     */
    @Transactional(readOnly = true)
    public List<TemperatureResponse> getReadingsForZone(String zoneName) {
        return temperatureRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(TemperatureResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get readings for a zone within a time range.
     *
     * The controller passes from/to as request parameters.
     * The service validates that from is before to — if not,
     * throw a clear error rather than running a nonsense query.
     *
     * This is business logic — it belongs in the service,
     * not the controller or repository.
     */
    @Transactional(readOnly = true)
    public List<TemperatureResponse> getReadingsForZoneBetween(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        // Validate time range — from must be before to
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return temperatureRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(TemperatureResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get the single latest reading for a zone.
     * Used by live dashboard to show current temperature.
     */
    @Transactional(readOnly = true)
    public TemperatureResponse getLatestForZone(String zoneName) {
        return temperatureRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(TemperatureResponse::from)
            .orElseThrow(() ->
                new RuntimeException("No temperature readings found for zone: " + zoneName)
            );
    }

    /**
     * Get last 20 readings for sparkline chart.
     * Used by dashboard zone cards — small temperature trend chart.
     */
    @Transactional(readOnly = true)
    public List<TemperatureResponse> getRecentReadings(String zoneName) {
        return temperatureRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(TemperatureResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get all readings where temperature dropped below threshold.
     *
     * Uses the LOW_TEMP_THRESHOLD constant defined above — 18.0°C.
     * This matches what your Python gateway uses in orchestration_config.py:
     *   self.temp_threshold_low = 18.0
     *
     * The controller doesn't pass the threshold — the service
     * owns this business rule. If the threshold ever changes,
     * you change it in one place only.
     */
    @Transactional(readOnly = true)
    public List<TemperatureResponse> getLowTemperatureAlerts(String zoneName) {
        return temperatureRepository
            .findLowTemperatureReadings(zoneName, LOW_TEMP_THRESHOLD)
            .stream()
            .map(TemperatureResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get readings for the last N hours for a zone.
     *
     * NEW CONCEPT: the service builds the time range itself.
     * The controller just passes "how many hours back" —
     * the service calculates the actual from/to timestamps.
     *
     * OffsetDateTime.now() = current date and time
     * .minusHours(hours)  = subtract N hours from now
     *
     * Example: getReadingsForLastHours("Zone_A", 24)
     *   from = now - 24 hours = yesterday at this time
     *   to   = now
     */
    @Transactional(readOnly = true)
    public List<TemperatureResponse> getReadingsForLastHours(
        String zoneName,
        int hours
    ) {
        OffsetDateTime to = OffsetDateTime.now();
        OffsetDateTime from = to.minusHours(hours);

        return temperatureRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(TemperatureResponse::from)
            .collect(Collectors.toList());
    }

}