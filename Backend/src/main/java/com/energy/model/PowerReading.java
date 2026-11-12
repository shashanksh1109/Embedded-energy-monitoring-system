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
 * One power reading. energyWh is the energy used during THIS interval only,
 * so total energy over any period is SUM(energy_wh).
 *
 * Maps to table: power_readings
 *
 * Marked Immutable: the backend only READS readings (the gateway writes them),
 * so Hibernate skips change-tracking for these objects.
 */
@Entity
@Table(name = "power_readings")
@Immutable
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PowerReading {

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

    @Column(name = "power_w", nullable = false)
    private Float powerW;

    @Column(name = "energy_wh", nullable = false)
    private Float energyWh;

    @Column(name = "interval_s", nullable = false)
    private Integer intervalS;

    /** When the device measured it (device clock). */
    @Column(name = "recorded_at", nullable = false)
    private OffsetDateTime recordedAt;

    /** When the gateway stored it (server clock). */
    @Column(name = "received_at", nullable = false)
    private OffsetDateTime receivedAt;

    /** Convenience for the API, which still reports kilowatts. Not a column. */
    public Float getPowerKw() {
        return powerW == null ? null : powerW / 1000f;
    }

    /** Convenience: energy of this interval in kWh. Not a column. */
    public Float getEnergyKwh() {
        return energyWh == null ? null : energyWh / 1000f;
    }
}