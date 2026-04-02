package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
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

    // Instantaneous power being consumed right now
    // = base_load_kw + (hvac_percentage / 100.0 * hvac_max_power_kw)
    // e.g. 2.0 kW base + 7.2 kW HVAC = 9.2 kW total
    @Column(name = "power_kw", nullable = false)
    private Float powerKw;

    // Cumulative energy consumed since power meter started
    // Calculated as: power_kw * (1 second / 3600 seconds) each iteration
    // Grows continuously — never resets within a session
    @Column(name = "energy_kwh", nullable = false)
    private Float energyKwh;

    // Cumulative cost in USD since power meter started
    // Calculated as: energy_kwh * $0.12 per kWh
    // Directly tied to energy_kwh — grows with it
    @Column(name = "cost_usd", nullable = false)
    private Float costUsd;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;

}