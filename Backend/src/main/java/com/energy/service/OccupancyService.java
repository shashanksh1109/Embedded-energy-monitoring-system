package com.energy.service;

import com.energy.dto.OccupancyResponse;
import com.energy.repository.OccupancyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OccupancyService {

    private final OccupancyRepository occupancyRepository;

    /**
     * Get all occupancy readings for a zone, newest first.
     */
    @Transactional(readOnly = true)
    public List<OccupancyResponse> getReadingsForZone(String zoneName) {
        return occupancyRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(OccupancyResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get readings for a zone within a time range.
     */
    @Transactional(readOnly = true)
    public List<OccupancyResponse> getReadingsForZoneBetween(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return occupancyRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(OccupancyResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get the latest occupancy reading for a zone.
     * Used by dashboard to show "Zone_A: 3 people" right now.
     */
    @Transactional(readOnly = true)
    public OccupancyResponse getLatestForZone(String zoneName) {
        return occupancyRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(OccupancyResponse::from)
            .orElseThrow(() ->
                new RuntimeException("No occupancy readings found for zone: " + zoneName)
            );
    }

    /**
     * Get last 20 readings for sparkline chart.
     */
    @Transactional(readOnly = true)
    public List<OccupancyResponse> getRecentReadings(String zoneName) {
        return occupancyRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(OccupancyResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Check if a zone is currently occupied.
     *
     * NEW CONCEPT: the service returns a simple boolean
     * instead of a full DTO — not every method needs to
     * return a complex object.
     *
     * Used by dashboard zone card:
     *   "Zone_A — OCCUPIED" or "Zone_A — EMPTY"
     *
     * Gets the latest reading and checks if occupancy_count > 0.
     * Returns false if no readings exist yet (safe default).
     */
    @Transactional(readOnly = true)
    public boolean isZoneOccupied(String zoneName) {
        return occupancyRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(reading -> reading.getOccupancyCount() > 0)
            .orElse(false);
    }

    /**
     * Get peak occupancy for a zone within a time range.
     *
     * Calls the MAX aggregate query from the repository.
     * Returns 0 if no readings exist in that range — safe default
     * instead of throwing an exception, because "no data" is a
     * valid state (zone might not have been active yet).
     */
    @Transactional(readOnly = true)
    public int getPeakOccupancy(String zoneName, OffsetDateTime from, OffsetDateTime to) {
        return occupancyRepository
            .findPeakOccupancy(zoneName, from, to)
            .orElse(0);
    }

    /**
     * Get readings for the last N hours.
     * Same pattern as TemperatureService.
     */
    @Transactional(readOnly = true)
    public List<OccupancyResponse> getReadingsForLastHours(String zoneName, int hours) {
        OffsetDateTime to = OffsetDateTime.now();
        OffsetDateTime from = to.minusHours(hours);

        return occupancyRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(OccupancyResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get all readings where zone was occupied within a time range.
     *
     * Uses the findOccupiedReadings custom query —
     * only returns rows where occupancy_count > 0.
     *
     * Used by "room utilisation" report on dashboard:
     * "Zone_A was occupied for 4.5 hours today"
     * The frontend calculates duration from these timestamps.
     */
    @Transactional(readOnly = true)
    public List<OccupancyResponse> getOccupiedReadings(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return occupancyRepository
            .findOccupiedReadings(zoneName, from, to)
            .stream()
            .map(OccupancyResponse::from)
            .collect(Collectors.toList());
    }

}