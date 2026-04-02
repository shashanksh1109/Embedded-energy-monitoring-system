package com.energy.repository;

import com.energy.model.OccupancyReading;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * OccupancyRepository - database access for occupancy_readings table
 */
@Repository
public interface OccupancyRepository extends JpaRepository<OccupancyReading, UUID> {

    /**
     * Get all occupancy readings for a zone, newest first.
     *
     * Generated SQL:
     *   SELECT o.* FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY o.recorded_at DESC
     */
    List<OccupancyReading> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get readings for a zone within a time range.
     *
     * Generated SQL:
     *   SELECT o.* FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   AND o.recorded_at BETWEEN ? AND ?
     *   ORDER BY o.recorded_at DESC
     */
    List<OccupancyReading> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        LocalDateTime from,
        LocalDateTime to
    );

    /**
     * Get the latest occupancy reading for a zone.
     * Used by dashboard to show "currently occupied / empty"
     *
     * Generated SQL:
     *   SELECT o.* FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY o.recorded_at DESC
     *   LIMIT 1
     */
    Optional<OccupancyReading> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get the last 20 readings for a zone.
     * Used for occupancy sparkline chart on dashboard.
     *
     * Generated SQL:
     *   SELECT o.* FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY o.recorded_at DESC
     *   LIMIT 20
     */
    List<OccupancyReading> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * CUSTOM QUERY — find all readings where zone was occupied
     * (occupancy_count > 0) within a time range.
     *
     * Used by dashboard to show "occupied hours" chart —
     * how many hours per day was this room actually in use?
     *
     * JPQL:
     *   o.occupancyCount > 0 = only rows where people were detected
     *
     * Generated SQL:
     *   SELECT o.* FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   AND o.recorded_at BETWEEN ? AND ?
     *   AND o.occupancy_count > 0
     *   ORDER BY o.recorded_at ASC
     */
    @Query("SELECT o FROM OccupancyReading o " +
           "WHERE o.zone.name = :zoneName " +
           "AND o.recordedAt BETWEEN :from AND :to " +
           "AND o.occupancyCount > 0 " +
           "ORDER BY o.recordedAt ASC")
    List<OccupancyReading> findOccupiedReadings(
        @Param("zoneName") String zoneName,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * CUSTOM QUERY — find peak occupancy reading for a zone today.
     *
     * MAX() is an aggregate function — it finds the highest value
     * across all matching rows. Returns a single Integer, not a list.
     *
     * Returns Optional<Integer> because if no readings exist
     * MAX() returns null from the database.
     *
     * Generated SQL:
     *   SELECT MAX(o.occupancy_count)
     *   FROM occupancy_readings o
     *   JOIN zones z ON o.zone_id = z.id
     *   WHERE z.name = ?
     *   AND o.recorded_at BETWEEN ? AND ?
     */
    @Query("SELECT MAX(o.occupancyCount) FROM OccupancyReading o " +
           "WHERE o.zone.name = :zoneName " +
           "AND o.recordedAt BETWEEN :from AND :to")
    Optional<Integer> findPeakOccupancy(
        @Param("zoneName") String zoneName,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

}