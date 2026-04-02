package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
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

    // How hard the heater is working — 0.0 means off, 100.0 means full power
    // When current_temp < setpoint, heater_pct > 0 and cooler_pct = 0
    @Column(name = "heater_pct", nullable = false)
    private Float heaterPct;

    // How hard the cooler is working — 0.0 means off, 100.0 means full power
    // When current_temp > setpoint, cooler_pct > 0 and heater_pct = 0
    @Column(name = "cooler_pct", nullable = false)
    private Float coolerPct;

    // The actual temperature reading at the time this state was recorded
    // This is what C PID controller is using as its input
    @Column(name = "current_temp", nullable = false)
    private Float currentTemp;

    // The target temperature the PID controller is trying to reach
    // Set by process_manager.py when it spawns hvac_controller
    @Column(name = "setpoint", nullable = false)
    private Float setpoint;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;

}