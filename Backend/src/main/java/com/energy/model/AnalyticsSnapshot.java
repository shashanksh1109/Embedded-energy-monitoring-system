package com.energy.model;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

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

    @Column(name = "snapshot_at", nullable = false)
    private OffsetDateTime snapshotAt;
}
