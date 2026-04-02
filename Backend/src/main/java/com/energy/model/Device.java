package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Device - Maps to the 'devices' table in PostgreSQL
 *
 * Key concept: Relationships
 *   In SQL you store a foreign key column (zone_id UUID).
 *   In JPA you store a reference to the actual Zone object.
 *   JPA handles the JOIN automatically when you load a Device.
 *
 *   @ManyToOne  - Many devices can belong to one zone
 *   @JoinColumn - the foreign key column name in THIS table
 *
 * Fetch types:
 *   LAZY  - don't load Zone from DB until you actually call getZone()
 *   EAGER - always load Zone immediately when loading Device
 *   LAZY is preferred for performance (default for @ManyToOne in some cases)
 */
@Entity
@Table(name = "devices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Device {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // Device identifier from the C sensor e.g. "TEMP_A", "HVAC_1"
    @Column(name = "device_id", nullable = false, unique = true, length = 16)
    private String deviceId;

    // Device type: TEMP_SENSOR, HVAC, POWER_METER, OCCUPANCY
    @Column(name = "device_type", nullable = false, length = 32)
    private String deviceType;

    /**
     * Relationship: Many devices → One zone
     *
     * In the database this is just a UUID column called zone_id.
     * In Java, JPA gives us the full Zone object automatically.
     *
     * FetchType.LAZY = only load Zone from DB when getZone() is called.
     * This is efficient — you don't always need zone details.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id", nullable = false)
    private Zone zone;

    // true = device is actively sending data
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

}