package com.energy.repository;

import com.energy.model.PowerReading;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * PowerReadingRepository - database access for power_readings table
 */
@Repository
public interface PowerReadingRepository extends JpaRepository<PowerReading, UUID> {

    /**
     * Get all power readings for a zone, newest first.
     *
     * Generated SQL:
     *   SELECT p.* FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY p.recorded_at DESC
     */
    List<PowerReading> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get power readings for a zone within a time range.
     *
     * Generated SQL:
     *   SELECT p.* FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   AND p.recorded_at BETWEEN ? AND ?
     *   ORDER BY p.recorded_at DESC
     */
    List<PowerReading> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    );

    /**
     * Get the latest power reading for a zone.
     * Used by dashboard to show current power consumption.
     *
     * Generated SQL:
     *   SELECT p.* FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY p.recorded_at DESC
     *   LIMIT 1
     */
    Optional<PowerReading> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get last 20 power readings for sparkline chart.
     *
     * Generated SQL:
     *   SELECT p.* FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY p.recorded_at DESC
     *   LIMIT 20
     */
    List<PowerReading> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * CUSTOM QUERY — calculate energy consumed in a time range.
     *
     * KEY CONCEPT: energy_kwh is cumulative — it grows continuously.
     * To find energy used in a specific window you need:
     *   MAX(energy_kwh) - MIN(energy_kwh)
     *
     * Example:
     *   At 9:00am  energy_kwh = 1.240
     *   At 10:00am energy_kwh = 1.892
     *   Energy used between 9am-10am = 1.892 - 1.240 = 0.652 kWh
     *
     * Generated SQL:
     *   SELECT MAX(p.energy_kwh) - MIN(p.energy_kwh)
     *   FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   AND p.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT MAX(p.energyKwh) - MIN(p.energyKwh) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findEnergyConsumed(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /**
     * CUSTOM QUERY — calculate cost in a time range.
     *
     * Same pattern as energy — cost_usd is cumulative.
     * MAX - MIN gives cost for that specific window.
     *
     * Generated SQL:
     *   SELECT MAX(p.cost_usd) - MIN(p.cost_usd)
     *   FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   AND p.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT MAX(p.costUsd) - MIN(p.costUsd) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findCostInRange(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /**
     * CUSTOM QUERY — find peak power consumption in a time range.
     *
     * power_kw is instantaneous — not cumulative.
     * MAX(power_kw) finds the single highest reading.
     *
     * Used by dashboard: "Peak load today: 9.2 kW at 08:00"
     *
     * Generated SQL:
     *   SELECT MAX(p.power_kw)
     *   FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   AND p.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT MAX(p.powerKw) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findPeakPower(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /**
     * CUSTOM QUERY — calculate average power consumption.
     *
     * AVG(power_kw) across all readings in the window.
     * Used for energy efficiency reports.
     *
     * Generated SQL:
     *   SELECT AVG(p.power_kw)
     *   FROM power_readings p
     *   JOIN zones z ON p.zone_id = z.id
     *   WHERE z.name = ?
     *   AND p.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT AVG(p.powerKw) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findAveragePower(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

}