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
 * A building owned by one organization. Zones live inside buildings.
 *
 * Maps to table: buildings
 *
 * orgId is stored as a plain UUID (not a link to the Organization entity):
 * it is used for filtering and for row-level security, and keeping it a
 * simple column avoids loading the organization every time a building is read.
 */
@Entity
@Table(name = "buildings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Building {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "org_id", nullable = false)
    private UUID orgId;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "address", length = 255)
    private String address;

    @Column(name = "timezone", nullable = false, length = 64)
    @Builder.Default
    private String timezone = "America/New_York";

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}