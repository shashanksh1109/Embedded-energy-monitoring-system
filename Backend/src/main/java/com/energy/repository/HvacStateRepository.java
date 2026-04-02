package com.energy.repository;

import com.energy.model.HvacState;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * HvacStateRepository - database access for hvac_state table
 */
@Repository
public interface HvacStateRepository extends JpaRepository<HvacState, UUID> {

    /**
     * Get all HVAC states for a zone, newest first.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY h.recorded_at DESC
     */
    List<HvacState> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get HVAC states for a zone within a time range.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   AND h.recorded_at BETWEEN ? AND ?
     *   ORDER BY h.recorded_at DESC
     */
    List<HvacState> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        LocalDateTime from,
        LocalDateTime to
    );

    /**
     * Get the latest HVAC state for a zone.
     * Used by dashboard to show current heating/cooling status.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY h.recorded_at DESC
     *   LIMIT 1
     */
    Optional<HvacState> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get last 20 HVAC states for sparkline chart on dashboard.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY h.recorded_at DESC
     *   LIMIT 20
     */
    List<HvacState> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * CUSTOM QUERY — find all states where HVAC was actively heating.
     *
     * heaterPct > 0 means the heater was running.
     * Used to calculate "total heating time" for energy reports.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   AND h.recorded_at BETWEEN ? AND ?
     *   AND h.heater_pct > 0
     *   ORDER BY h.recorded_at ASC
     */
    @Query("SELECT h FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to " +
           "AND h.heaterPct > 0 " +
           "ORDER BY h.recordedAt ASC")
    List<HvacState> findHeatingStates(
        @Param("zoneName") String zoneName,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * CUSTOM QUERY — find all states where HVAC was actively cooling.
     *
     * coolerPct > 0 means the cooler was running.
     * Used to calculate "total cooling time" for energy reports.
     *
     * Generated SQL:
     *   SELECT h.* FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   AND h.recorded_at BETWEEN ? AND ?
     *   AND h.cooler_pct > 0
     *   ORDER BY h.recorded_at ASC
     */
    @Query("SELECT h FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to " +
           "AND h.coolerPct > 0 " +
           "ORDER BY h.recordedAt ASC")
    List<HvacState> findCoolingStates(
        @Param("zoneName") String zoneName,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * CUSTOM QUERY — calculate average heater and cooler usage
     * for a zone within a time range.
     *
     * NEW CONCEPT: returning multiple aggregates at once using Object[]
     *
     * AVG() calculates the mean across all matching rows.
     * Returning two values as Object[] — index 0 = avg heater,
     * index 1 = avg cooler.
     *
     * Used by dashboard energy summary:
     *   "Zone_A averaged 42% heater usage today"
     *
     * Generated SQL:
     *   SELECT AVG(h.heater_pct), AVG(h.cooler_pct)
     *   FROM hvac_state h
     *   JOIN zones z ON h.zone_id = z.id
     *   WHERE z.name = ?
     *   AND h.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT AVG(h.heaterPct), AVG(h.coolerPct) " +
           "FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to")
    Optional<Object[]> findAverageUsage(
        @Param("zoneName") String zoneName,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

}