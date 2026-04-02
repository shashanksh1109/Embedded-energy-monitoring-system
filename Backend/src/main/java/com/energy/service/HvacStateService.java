package com.energy.service;

import com.energy.dto.HvacStateResponse;
import com.energy.repository.HvacStateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HvacStateService {

    private final HvacStateRepository hvacStateRepository;

    /**
     * Get all HVAC states for a zone, newest first.
     */
    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForZone(String zoneName) {
        return hvacStateRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get HVAC states for a zone within a time range.
     */
    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForZoneBetween(
        String zoneName,
        LocalDateTime from,
        LocalDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return hvacStateRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get the latest HVAC state for a zone.
     * Used by dashboard to show current heating/cooling status.
     */
    @Transactional(readOnly = true)
    public HvacStateResponse getLatestForZone(String zoneName) {
        return hvacStateRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(HvacStateResponse::from)
            .orElseThrow(() ->
                new RuntimeException("No HVAC state found for zone: " + zoneName)
            );
    }

    /**
     * Get last 20 HVAC states for sparkline chart.
     */
    @Transactional(readOnly = true)
    public List<HvacStateResponse> getRecentStates(String zoneName) {
        return hvacStateRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get current HVAC mode for a zone.
     * Returns "HEATING", "COOLING", or "IDLE".
     *
     * Same pattern as isZoneOccupied in OccupancyService —
     * returns a simple String instead of a full DTO.
     * Used by dashboard status badge.
     */
    @Transactional(readOnly = true)
    public String getCurrentMode(String zoneName) {
        return hvacStateRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(state -> {
                if (state.getHeaterPct() > 0) return "HEATING";
                if (state.getCoolerPct() > 0) return "COOLING";
                return "IDLE";
            })
            .orElse("IDLE");
    }

    /**
     * Get HVAC usage summary for a zone within a time range.
     *
     * NEW CONCEPT: building and returning a Map instead of a DTO.
     *
     * This method calls three repository queries and combines
     * the results into one Map with meaningful keys.
     *
     * Why a Map and not a DTO?
     * This is a one-off summary response — creating a dedicated
     * DTO class for it would be overkill. A Map<String, Object>
     * is flexible enough and Spring serializes it to JSON cleanly:
     * {
     *   "avgHeaterPct": 42.5,
     *   "avgCoolerPct": 12.3,
     *   "heatingReadings": 245,
     *   "coolingReadings": 87
     * }
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getUsageSummary(
        String zoneName,
        LocalDateTime from,
        LocalDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        // Get average heater and cooler usage from Object[] query
        // Object[] layout: [0] = avgHeater, [1] = avgCooler
        Object[] avgUsage = hvacStateRepository
            .findAverageUsage(zoneName, from, to)
            .orElse(new Object[]{0.0, 0.0});

        // Count how many readings were actively heating
        int heatingCount = hvacStateRepository
            .findHeatingStates(zoneName, from, to)
            .size();

        // Count how many readings were actively cooling
        int coolingCount = hvacStateRepository
            .findCoolingStates(zoneName, from, to)
            .size();

        // Build and return the summary map
        // Map.of() creates an immutable map with key-value pairs
        return Map.of(
            "zoneName",        zoneName,
            "avgHeaterPct",    avgUsage[0],
            "avgCoolerPct",    avgUsage[1],
            "heatingReadings", heatingCount,
            "coolingReadings", coolingCount,
            "from",            from,
            "to",              to
        );
    }

    /**
     * Get readings for the last N hours.
     */
    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForLastHours(String zoneName, int hours) {
        LocalDateTime to = LocalDateTime.now();
        LocalDateTime from = to.minusHours(hours);

        return hvacStateRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

}