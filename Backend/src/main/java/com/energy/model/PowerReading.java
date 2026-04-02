package com.energy.model;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "power_readings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PowerReading {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "device_id", nullable = false, length = 16)
    private String deviceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    @Column(name = "power_kw", nullable = false)
    private Float powerKw;

    @Column(name = "energy_kwh", nullable = false)
    private Float energyKwh;

    @Column(name = "cost_usd", nullable = false)
    private Float costUsd;

    @Column(name = "recorded_at", nullable = false)
    private OffsetDateTime recordedAt;
}
