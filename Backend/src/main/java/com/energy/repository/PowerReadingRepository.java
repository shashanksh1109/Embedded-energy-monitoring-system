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
 * PowerReadingRepository - database access for the power_readings table
 *
 * Each row stores the energy used during ITS OWN interval (energy_wh),
 * so the total energy over any period is SUM(energy_wh).
 */
@Repository
public interface PowerReadingRepository extends JpaRepository<PowerReading, UUID> {

    List<PowerReading> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    List<PowerReading> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    );

    Optional<PowerReading> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    List<PowerReading> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Total energy used in the range, in watt-hours.
     * (Replaces MAX(energy_kwh) - MIN(energy_kwh), which assumed a running
     * total and gave close to 0 for per-interval values.)
     */
    @Query("SELECT SUM(p.energyWh) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findTotalEnergyWh(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /**
     * Highest instantaneous power in the range, in watts.
     * MAX() returns the field's own type (Float), so it is CAST to Double
     * to match the Optional<Double> return type.
     */
    @Query("SELECT CAST(MAX(p.powerW) AS Double) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findPeakPowerW(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /** Average instantaneous power in the range, in watts. */
    @Query("SELECT AVG(p.powerW) " +
           "FROM PowerReading p " +
           "WHERE p.zone.name = :zoneName " +
           "AND p.recordedAt BETWEEN :from AND :to")
    Optional<Double> findAveragePowerW(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );
}