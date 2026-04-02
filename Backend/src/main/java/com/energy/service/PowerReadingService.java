package com.energy.service;

import com.energy.dto.PowerReadingResponse;
import com.energy.repository.PowerReadingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PowerReadingService {

    private final PowerReadingRepository powerReadingRepository;

    // Electricity cost per kWh — matches power_meter.c
    // #define ELECTRICITY_COST_PER_KWH 0.12
    private static final double COST_PER_KWH = 0.12;

    /**
     * Get all power readings for a zone, newest first.
     */
    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForZone(String zoneName) {
        return powerReadingRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get power readings for a zone within a time range.
     */
    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForZoneBetween(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        return powerReadingRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get the latest power reading for a zone.
     * Used by dashboard to show current kW consumption.
     */
    @Transactional(readOnly = true)
    public PowerReadingResponse getLatestForZone(String zoneName) {
        return powerReadingRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(PowerReadingResponse::from)
            .orElseThrow(() ->
                new RuntimeException("No power readings found for zone: " + zoneName)
            );
    }

    /**
     * Get last 20 readings for sparkline chart.
     */
    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getRecentReadings(String zoneName) {
        return powerReadingRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get readings for the last N hours.
     */
    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForLastHours(String zoneName, int hours) {
        OffsetDateTime to = OffsetDateTime.now();
        OffsetDateTime from = to.minusHours(hours);

        return powerReadingRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get energy and cost summary for a zone within a time range.
     *
     * NEW CONCEPT: combining multiple repository aggregate queries
     * and doing additional calculation in the service layer.
     *
     * Remember from PowerReadingRepository:
     *   findEnergyConsumed → MAX(energy_kwh) - MIN(energy_kwh)
     *   findCostInRange    → MAX(cost_usd)   - MIN(cost_usd)
     *   findPeakPower      → MAX(power_kw)
     *   findAveragePower   → AVG(power_kw)
     *
     * The service collects all four results and builds one
     * clean summary Map for the dashboard energy report page.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getEnergySummary(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException(
                "Invalid time range: 'from' must be before 'to'"
            );
        }

        // Energy consumed in this window (kWh)
        // MAX(energy_kwh) - MIN(energy_kwh)
        double energyConsumed = powerReadingRepository
            .findEnergyConsumed(zoneName, from, to)
            .orElse(0.0);

        // Cost incurred in this window ($)
        // MAX(cost_usd) - MIN(cost_usd)
        double costInRange = powerReadingRepository
            .findCostInRange(zoneName, from, to)
            .orElse(0.0);

        // Peak instantaneous power (kW)
        double peakPower = powerReadingRepository
            .findPeakPower(zoneName, from, to)
            .orElse(0.0);

        // Average instantaneous power (kW)
        double avgPower = powerReadingRepository
            .findAveragePower(zoneName, from, to)
            .orElse(0.0);

        // NEW: calculate projected monthly cost from average power
        // avgPower (kW) × 24 hours × 30 days × cost per kWh
        // This is a service-layer calculation — not stored in DB,
        // not done in the repository — pure business logic
        double projectedMonthlyCost = avgPower * 24 * 30 * COST_PER_KWH;

        return Map.of(
            "zoneName",             zoneName,
            "energyConsumedKwh",    energyConsumed,
            "totalCostUsd",         costInRange,
            "peakPowerKw",          peakPower,
            "avgPowerKw",           avgPower,
            "projectedMonthlyCost", projectedMonthlyCost,
            "from",                 from,
            "to",                   to
        );
    }

}