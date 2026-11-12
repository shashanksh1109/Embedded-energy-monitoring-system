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
 * One temperature (and optional humidity) reading.
 *
 * Maps to table: temperature_readings
 *
 * Marked Immutable: the backend only READS readings (the gateway writes them),
 * so Hibernate skips change-tracking for these objects.
 */
@Entity
@Table(name = "temperature_readings")
@Immutable
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TemperatureReading {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "org_id", nullable = false)
    private UUID orgId;

    /** The device that sent this reading (device.getThingName() is e.g. "TEMP_A"). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id", nullable = false)
    private Device device;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    @Column(name = "temperature_c", nullable = false)
    private Float temperatureC;

    /** NULL for sensors without humidity (e.g. the Raspberry Pi SoC sensor). */
    @Column(name = "humidity_pct")
    private Float humidityPct;

    /** When the device measured it (device clock). */
    @Column(name = "recorded_at", nullable = false)
    private OffsetDateTime recordedAt;

    /** When the gateway stored it (server clock). */
    @Column(name = "received_at", nullable = false)
    private OffsetDateTime receivedAt;
}