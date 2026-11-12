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
 * A physical or simulated device (sensor, HVAC controller, power meter).
 *
 * Maps to table: devices
 *
 * thingName is the name the device sends in its packets (e.g. "TEMP_A")
 * and, later, its identity in AWS IoT Core.
 *
 * Lifecycle: PENDING (registered, not yet claimed) -> ACTIVE -> DISABLED.
 * Only ACTIVE devices that are placed in a zone have their readings stored.
 */
@Entity
@Table(name = "devices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Device {

    public enum Status { PENDING, ACTIVE, DISABLED }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "org_id", nullable = false)
    private UUID orgId;

    /** NULL until the customer places the device in a zone. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zone_id")
    private Zone zone;

    @Column(name = "thing_name", nullable = false, unique = true, length = 128)
    private String thingName;

    @Column(name = "device_type", nullable = false, length = 32)
    private String deviceType;

    @Column(name = "display_name", length = 120)
    private String displayName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    @Builder.Default
    private Status status = Status.PENDING;

    /** Hash of the one-time claim code. The code itself is never stored. */
    @Column(name = "claim_code_hash", length = 128)
    private String claimCodeHash;

    @Column(name = "claim_expires_at")
    private OffsetDateTime claimExpiresAt;

    @Column(name = "claimed_at")
    private OffsetDateTime claimedAt;

    /** Updated by the gateway; drives online/offline on the dashboard. */
    @Column(name = "last_seen_at")
    private OffsetDateTime lastSeenAt;

    @Column(name = "firmware_version", length = 32)
    private String firmwareVersion;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}