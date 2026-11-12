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

/**
 * PowerReadingService - business logic for power readings
 */
@Service
@RequiredArgsConstructor
public class PowerReadingService {

    private final PowerReadingRepository powerReadingRepository;

    /** Same price as the DTO, so every cost in the API agrees. */
    private static final double COST_PER_KWH = PowerReadingResponse.COST_PER_KWH;

    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForZone(String zoneName) {
        return powerReadingRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForZoneBetween(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException("Invalid time range: 'from' must be before 'to'");
        }
        return powerReadingRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PowerReadingResponse getLatestForZone(String zoneName) {
        return powerReadingRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(PowerReadingResponse::from)
            .orElse(null);
    }

    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getRecentReadings(String zoneName) {
        return powerReadingRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PowerReadingResponse> getReadingsForLastHours(String zoneName, int hours) {
        OffsetDateTime to = OffsetDateTime.now(java.time.ZoneOffset.UTC);
        OffsetDateTime from = to.minusHours(hours);
        return powerReadingRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(PowerReadingResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Energy summary for a time range. The JSON keys are unchanged.
     *
     * energyConsumedKwh = SUM(energy_wh) / 1000
     * totalCostUsd      = energyConsumedKwh * price
     * peak/avg power    = watts / 1000, reported in kW
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getEnergySummary(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException("Invalid time range: 'from' must be before 'to'");
        }

        double energyKwh = powerReadingRepository
            .findTotalEnergyWh(zoneName, from, to)
            .orElse(0.0) / 1000.0;

        double totalCost = energyKwh * COST_PER_KWH;

        double peakPowerKw = powerReadingRepository
            .findPeakPowerW(zoneName, from, to)
            .orElse(0.0) / 1000.0;

        double avgPowerKw = powerReadingRepository
            .findAveragePowerW(zoneName, from, to)
            .orElse(0.0) / 1000.0;

        // average kW x 24 h x 30 days x price
        double projectedMonthlyCost = avgPowerKw * 24 * 30 * COST_PER_KWH;

        return Map.of(
            "zoneName",             zoneName,
            "energyConsumedKwh",    energyKwh,
            "totalCostUsd",         totalCost,
            "peakPowerKw",          peakPowerKw,
            "avgPowerKw",           avgPowerKw,
            "projectedMonthlyCost", projectedMonthlyCost,
            "from",                 from,
            "to",                   to
        );
    }
}