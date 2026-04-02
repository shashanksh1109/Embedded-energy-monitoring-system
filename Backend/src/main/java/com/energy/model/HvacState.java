package com.energy.model;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "hvac_state")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HvacState {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "device_id", nullable = false, length = 16)
    private String deviceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    @Column(name = "heater_pct", nullable = false)
    private Float heaterPct;

    @Column(name = "cooler_pct", nullable = false)
    private Float coolerPct;

    @Column(name = "current_temp", nullable = false)
    private Float currentTemp;

    @Column(name = "setpoint", nullable = false)
    private Float setpoint;

    @Column(name = "recorded_at", nullable = false)
    private OffsetDateTime recordedAt;
}
