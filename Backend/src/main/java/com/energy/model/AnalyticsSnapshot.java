package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Immutable;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Statistics for one zone and one metric over one time window,
 * computed by the gateway's analytics engine (every 60 s by default).
 *
 * Maps to table: analytics_snapshots
 *
 * The window runs from windowStart to snapshotAt.
 * Marked Immutable: the backend only reads snapshots (the gateway writes them).
 */
@Entity
@Table(name = "analytics_snapshots")
@Immutable
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "org_id", nullable = false)
    private UUID orgId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    /** e.g. "TEMP", "POWER", "OCCUPANCY" */
    @Column(name = "metric_type", nullable = false, length = 32)
    private String metricType;

    @Column(name = "mean_val", nullable = false)
    private Float meanVal;

    @Column(name = "stddev_val", nullable = false)
    private Float stddevVal;

    @Column(name = "min_val", nullable = false)
    private Float minVal;

    @Column(name = "max_val", nullable = false)
    private Float maxVal;

    @Column(name = "sample_count", nullable = false)
    private Integer sampleCount;

    /** Start of the window. NULL only for snapshots written before this column existed. */
    @Column(name = "window_start")
    private OffsetDateTime windowStart;

    /** End of the window. */
    @Column(name = "snapshot_at", nullable = false)
    private OffsetDateTime snapshotAt;
}