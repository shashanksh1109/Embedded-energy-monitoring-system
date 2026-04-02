package com.energy.model;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "occupancy_readings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OccupancyReading {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "device_id", nullable = false, length = 16)
    private String deviceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    @Column(name = "occupancy_count", nullable = false)
    private Integer occupancyCount;

    @Column(name = "distance_mm", nullable = false)
    private Float distanceMm;

    @Column(name = "recorded_at", nullable = false)
    private OffsetDateTime recordedAt;
}
