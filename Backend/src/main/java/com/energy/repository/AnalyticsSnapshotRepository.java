package com.energy.repository;

import com.energy.model.AnalyticsSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * AnalyticsSnapshotRepository - database access for analytics_snapshots table
 */
@Repository
public interface AnalyticsSnapshotRepository extends JpaRepository<AnalyticsSnapshot, UUID> {

    /**
     * Get all snapshots for a zone and metric type, newest first.
     *
     * Two filters chained together:
     *   ZoneName   → JOIN zones WHERE z.name = ?
     *   MetricType → AND metric_type = ?
     *
     * Generated SQL:
     *   SELECT a.* FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE z.name = ?
     *   AND a.metric_type = ?
     *   ORDER BY a.snapshot_at DESC
     *
     * Example call:
     *   findByZoneNameAndMetricTypeOrderBySnapshotAtDesc("Zone_A", "TEMP")
     */
    List<AnalyticsSnapshot> findByZoneNameAndMetricTypeOrderBySnapshotAtDesc(
        String zoneName,
        String metricType
    );

    /**
     * Get snapshots for a zone, metric type, and time range.
     * The most common query — "show me TEMP stats for Zone_A today"
     *
     * Generated SQL:
     *   SELECT a.* FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE z.name = ?
     *   AND a.metric_type = ?
     *   AND a.snapshot_at BETWEEN ? AND ?
     *   ORDER BY a.snapshot_at DESC
     */
    List<AnalyticsSnapshot> findByZoneNameAndMetricTypeAndSnapshotAtBetweenOrderBySnapshotAtDesc(
        String zoneName,
        String metricType,
        OffsetDateTime from,
        OffsetDateTime to
    );

    /**
     * Get the latest snapshot for a zone and metric type.
     * Used by dashboard summary cards:
     *   "Last 60s average: 21.4°C"
     *
     * Generated SQL:
     *   SELECT a.* FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE z.name = ?
     *   AND a.metric_type = ?
     *   ORDER BY a.snapshot_at DESC
     *   LIMIT 1
     */
    Optional<AnalyticsSnapshot> findTop1ByZoneNameAndMetricTypeOrderBySnapshotAtDesc(
        String zoneName,
        String metricType
    );

    /**
     * Get all snapshots for a zone across ALL metric types.
     * Used when building a full zone summary page —
     * you want TEMP, OCCUPANCY, POWER and HVAC stats together.
     *
     * Generated SQL:
     *   SELECT a.* FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE z.name = ?
     *   AND a.snapshot_at BETWEEN ? AND ?
     *   ORDER BY a.snapshot_at DESC
     */
    List<AnalyticsSnapshot> findByZoneNameAndSnapshotAtBetweenOrderBySnapshotAtDesc(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    );

    /**
     * CUSTOM QUERY — calculate the overall average of mean values
     * for a zone and metric type over a time range.
     *
     * This is AVG of AVGs — the mean_val column already contains
     * a 60-second average. Taking AVG(mean_val) across multiple
     * snapshots gives you the average over a longer period.
     *
     * Example:
     *   Snapshot 1: mean_val = 21.4  (60s average)
     *   Snapshot 2: mean_val = 21.8  (60s average)
     *   Snapshot 3: mean_val = 21.2  (60s average)
     *   AVG(mean_val) = 21.47        (3-minute average)
     *
     * Generated SQL:
     *   SELECT AVG(a.mean_val)
     *   FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE z.name = ?
     *   AND a.metric_type = ?
     *   AND a.snapshot_at BETWEEN ? AND ?
     */
    @Query("SELECT AVG(a.meanVal) FROM AnalyticsSnapshot a " +
           "WHERE a.zone.name = :zoneName " +
           "AND a.metricType = :metricType " +
           "AND a.snapshotAt BETWEEN :from AND :to")
    Optional<Double> findOverallAverage(
        @Param("zoneName") String zoneName,
        @Param("metricType") String metricType,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /**
     * CUSTOM QUERY — get a summary of all zones for a metric type
     * at the latest snapshot time.
     *
     * NEW CONCEPT: returning a custom projection — multiple fields
     * from multiple rows in one query, grouped by zone.
     *
     * Used by dashboard overview page:
     *   Zone_A | TEMP | avg: 21.4 | min: 17.4 | max: 24.5
     *   Zone_B | TEMP | avg: 20.1 | min: 19.8 | max: 20.6
     *   Zone_C | TEMP | avg: 18.2 | min: 15.0 | max: 21.0
     *
     * Object[] layout:
     *   [0] = zone name  (String)
     *   [1] = mean_val   (Double)
     *   [2] = min_val    (Double)
     *   [3] = max_val    (Double)
     *   [4] = sample_count (Integer)
     *
     * Generated SQL:
     *   SELECT z.name, a.mean_val, a.min_val, a.max_val, a.sample_count
     *   FROM analytics_snapshots a
     *   JOIN zones z ON a.zone_id = z.id
     *   WHERE a.metric_type = ?
     *   AND a.snapshot_at = (
     *       SELECT MAX(snapshot_at) FROM analytics_snapshots
     *       WHERE metric_type = ?
     *   )
     */
    @Query("SELECT a.zone.name, a.meanVal, a.minVal, a.maxVal, a.sampleCount " +
           "FROM AnalyticsSnapshot a " +
           "WHERE a.metricType = :metricType " +
           "AND a.snapshotAt = (" +
           "   SELECT MAX(a2.snapshotAt) FROM AnalyticsSnapshot a2 " +
           "   WHERE a2.metricType = :metricType" +
           ")")
    List<Object[]> findLatestSummaryAllZones(@Param("metricType") String metricType);

}