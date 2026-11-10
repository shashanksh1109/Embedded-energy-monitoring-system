package com.energy.service;

import com.energy.dto.HvacStateResponse;
import com.energy.repository.HvacStateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * HvacStateService - business logic for HVAC state
 */
@Service
@RequiredArgsConstructor
public class HvacStateService {

    private final HvacStateRepository hvacStateRepository;

    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForZone(String zoneName) {
        return hvacStateRepository
            .findByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForZoneBetween(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException("Invalid time range: 'from' must be before 'to'");
        }
        return hvacStateRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public HvacStateResponse getLatestForZone(String zoneName) {
        return hvacStateRepository
            .findTop1ByZoneNameOrderByRecordedAtDesc(zoneName)
            .map(HvacStateResponse::from)
            .orElse(null);
    }

    @Transactional(readOnly = true)
    public List<HvacStateResponse> getRecentStates(String zoneName) {
        return hvacStateRepository
            .findTop20ByZoneNameOrderByRecordedAtDesc(zoneName)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }

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
     * Usage summary for a time range. JSON keys are unchanged.
     * The heating/cooling counts now come from COUNT queries in the database.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getUsageSummary(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    ) {
        if (from.isAfter(to)) {
            throw new RuntimeException("Invalid time range: 'from' must be before 'to'");
        }

        // [0] = avg heater %, [1] = avg cooler %. AVG over zero rows is NULL, so default to 0.
        Object[] avg = hvacStateRepository
            .findAverageUsage(zoneName, from, to)
            .orElse(new Object[]{0.0, 0.0});
        Object avgHeater = avg.length > 0 && avg[0] != null ? avg[0] : 0.0;
        Object avgCooler = avg.length > 1 && avg[1] != null ? avg[1] : 0.0;

        long heatingCount = hvacStateRepository.countHeatingStates(zoneName, from, to);
        long coolingCount = hvacStateRepository.countCoolingStates(zoneName, from, to);

        return Map.of(
            "zoneName",        zoneName,
            "avgHeaterPct",    avgHeater,
            "avgCoolerPct",    avgCooler,
            "heatingReadings", heatingCount,
            "coolingReadings", coolingCount,
            "from",            from,
            "to",              to
        );
    }

    @Transactional(readOnly = true)
    public List<HvacStateResponse> getStatesForLastHours(String zoneName, int hours) {
        OffsetDateTime to = OffsetDateTime.now(java.time.ZoneOffset.UTC);
        OffsetDateTime from = to.minusHours(hours);
        return hvacStateRepository
            .findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(zoneName, from, to)
            .stream()
            .map(HvacStateResponse::from)
            .collect(Collectors.toList());
    }
}