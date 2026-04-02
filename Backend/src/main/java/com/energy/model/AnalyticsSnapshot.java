package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "analytics_snapshots")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // No device_id here — analytics belong to a zone, not a specific sensor
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    // Which metric this snapshot is for
    // One of: "TEMP", "OCCUPANCY", "POWER", "HVAC"
    // This is how one table stores stats for all four sensor types
    @Column(name = "metric_type", nullable = false, length = 32)
    private String metricType;

    // Average value across all readings in this snapshot window (60 seconds)
    // For TEMP: average °C
    // For OCCUPANCY: average people count
    // For POWER: average kW
    // For HVAC: average heater percentage
    @Column(name = "mean_val", nullable = false)
    private Float meanVal;

    // Standard deviation — measures how spread out the values were
    // Low stddev = stable readings (e.g. temperature held steady)
    // High stddev = lots of variation (e.g. people coming and going)
    @Column(name = "stddev_val", nullable = false)
    private Float stddevVal;

    // The lowest value seen in this 60-second window
    @Column(name = "min_val", nullable = false)
    private Float minVal;

    // The highest value seen in this 60-second window
    @Column(name = "max_val", nullable = false)
    private Float maxVal;

    // How many readings were included in this snapshot
    // Depends on how many sensors were active and their sampling rates
    @Column(name = "sample_count", nullable = false)
    private Integer sampleCount;

    // When this snapshot was calculated — every 60 seconds by analytics.py
    @Column(name = "snapshot_at", nullable = false)
    private LocalDateTime snapshotAt;

}