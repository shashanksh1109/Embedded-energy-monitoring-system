package com.energy.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * A room or area inside a building. Devices are placed in zones.
 *
 * Maps to table: zones
 *
 * Zone names are unique per BUILDING (two customers can both have "Room 1"),
 * so name is no longer unique on its own.
 */
@Entity
@Table(name = "zones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Zone {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "org_id", nullable = false)
    private UUID orgId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id", nullable = false)
    private Building building;

    @Column(name = "name", nullable = false, length = 64)
    private String name;

    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "capacity", nullable = false)
    @Builder.Default
    private Integer capacity = 0;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}