package com.energy.repository;

import com.energy.model.TemperatureReading;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * TemperatureRepository - database access for temperature_readings table
 */
@Repository
public interface TemperatureRepository extends JpaRepository<TemperatureReading, UUID> {

    /**
     * Get all readings for a zone, newest first.
     *
     * Generated SQL:
     *   SELECT t.* FROM temperature_readings t
     *   JOIN zones z ON t.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY t.recorded_at DESC
     */
    List<TemperatureReading> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get readings for a zone within a time range, newest first.
     *
     * "Between" in the method name generates:
     *   WHERE recorded_at >= ? AND recorded_at <= ?
     *
     * Generated SQL:
     *   SELECT t.* FROM temperature_readings t
     *   JOIN zones z ON t.zone_id = z.id
     *   WHERE z.name = ?
     *   AND t.recorded_at BETWEEN ? AND ?
     *   ORDER BY t.recorded_at DESC
     *
     * This is the most common query — dashboard asks for
     * "last 1 hour" or "today" or "last 7 days"
     */
    List<TemperatureReading> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        LocalDateTime from,
        LocalDateTime to
    );

    /**
     * Get the single most recent reading for a zone.
     * Used by the live dashboard to show current temperature.
     *
     * "Top1" = LIMIT 1 in SQL
     *
     * Generated SQL:
     *   SELECT t.* FROM temperature_readings t
     *   JOIN zones z ON t.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY t.recorded_at DESC
     *   LIMIT 1
     *
     * Returns Optional because there might be no readings yet.
     */
    Optional<TemperatureReading> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * Get the last N readings for a zone.
     * Used for sparkline charts on the dashboard — last 20 readings.
     *
     * "Top" + number = LIMIT that number
     *
     * Generated SQL:
     *   SELECT t.* FROM temperature_readings t
     *   JOIN zones z ON t.zone_id = z.id
     *   WHERE z.name = ?
     *   ORDER BY t.recorded_at DESC
     *   LIMIT 20
     */
    List<TemperatureReading> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * CUSTOM QUERY — when method names get too long or complex,
     * you can write JPQL (Java Persistence Query Language) directly.
     *
     * JPQL looks like SQL but uses Java class names and field names
     * instead of table names and column names.
     *
     * "t" is an alias for TemperatureReading
     * "t.zone.name" = follow the zone relationship, get its name field
     * "t.temperatureC" = the temperatureC field on TemperatureReading
     *
     * This finds all readings where temperature was dangerously low
     * (below 15°C) — useful for alerts on the dashboard.
     *
     * @Query = you write the query yourself instead of using method names
     * @Param = bind the method parameter to the :zoneName placeholder in the query
     */
    @Query("SELECT t FROM TemperatureReading t " +
           "WHERE t.zone.name = :zoneName " +
           "AND t.temperatureC < :threshold " +
           "ORDER BY t.recordedAt DESC")
    List<TemperatureReading> findLowTemperatureReadings(
        @Param("zoneName") String zoneName,
        @Param("threshold") Float threshold
    );

}